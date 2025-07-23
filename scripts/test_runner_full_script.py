
import base64
import os
import requests
import yaml


def update_existing_policy():
    existing_policy_file = 'tests/policies/existing-policy.yaml'
    created_yaml = os.getenv('filename')
    print(f"🔍 Processing: {created_yaml}")

    repo = os.getenv('repo')
    token = os.getenv('token')

    yaml_filename = ''

    if created_yaml:
        yaml_filename = os.path.basename(created_yaml)

    try:
        with open(created_yaml, 'r') as f:
            new_yaml = yaml.safe_load(f)
        print(new_yaml)
        service_type = new_yaml['security_group'].get('serviceType', '')
        ip_direction_key = 'source' if service_type == 'privatelink-consumer' else 'destination'
    except yaml.YAMLError as e:
        return print(f"❌ Error parsing YAML: {e}")

    if 'policies' in created_yaml:
        yaml_filename = created_yaml.replace('policies/', '')

    duplicates_within, duplicate_ips_found = check_duplicates_within(new_yaml, ip_direction_key)
    if len(duplicates_within) != 0:
        with open(os.environ.get('GITHUB_OUTPUT', 'GITHUB_OUTPUT.txt'), 'a') as fh:
            fh.write(f'duplicates_within={duplicates_within}')

    # Hardcoded compare: always test against 'existing-policy.yaml'
    found_file = 'existing-policy.yaml'
    original_yaml = get_file_contents(repo, found_file, token)

    duplicates, rule_nums, rules_to_add, duplicate_ips_found = check_duplicates(original_yaml, new_yaml, ip_direction_key)

    if len(duplicates) != 0:
        pointer_yaml = point_out_dupes(duplicates, duplicate_ips_found)
        with open(os.environ.get('GITHUB_OUTPUT', 'GITHUB_OUTPUT.txt'), 'a') as fh:
            fh.write(f'duplicates={pointer_yaml}\n')
            fh.write(f'rule_nums={rule_nums}\n')

    if len(rules_to_add) != 0:
        print(f"✅ No duplicate rules, but new rules exist and were not written (dry run only).")
    else:
        print(f"✅ All rules already exist — no new rules to add.")


def check_duplicates_within(new, ip_direction_key):
    rows = []
    seen = set()
    duplicates = []
    dupe_ips = []
    duplicate_ips_within_rule = []

    for rule_idx, rules in enumerate(new['rules']):
        ips = rules[ip_direction_key]['ips']
        seen_ips = set()
        for ip in ips:
            if ip in seen_ips:
                duplicate_ips_within_rule.append((rule_idx + 1, ip))
            seen_ips.add(ip)

        for ip in ips:
            row = {
                'ip': ip,
                'proto': rules['protocol'],
                'port': rules['port'],
                'appid': rules['appid'],
                'url': rules['url']
            }
            frozen_dict = frozenset(row.items())
            if frozen_dict in seen:
                duplicates.append(rules)
                dupe_ips.append(ip)
            else:
                seen.add(frozen_dict)

    if duplicate_ips_within_rule:
        print("⚠️ Duplicate IPs found within individual rule blocks:")
        for rule_num, ip in duplicate_ips_within_rule:
            print(f"   • Rule #{rule_num}: IP {ip} is listed more than once")

    return duplicates, dupe_ips


def check_duplicates(original, new, ip_direction_key):
    orig_set = []

    for orig_rules in original['rules']:
        for ip in orig_rules[ip_direction_key]['ips']:
            row = {
                'ip': ip, 
                'proto': orig_rules['protocol'],
                'port': orig_rules['port'],
                'appid': orig_rules['appid'],
                'url': orig_rules['url']
            }
            orig_set.append(row)

    duplicates = []
    append_rules = []
    rule_count_list = []
    rule_count = 0
    duplicate_ips = []

    for new_rules in new['rules']:
        rule_count += 1
        has_duplicate = False

        for ip in new_rules[ip_direction_key]['ips']:
            for set in orig_set:
                if (
                    ip == set['ip']
                    and str(new_rules['protocol']) == str(set['proto'])
                    and str(new_rules['port']) == str(set['port'])  # <- normalize both sides
                ):
                    has_duplicate = True
                    duplicate_ips.append(ip)
                    break
        if has_duplicate:
            duplicates.append(new_rules)
            rule_count_list.append(rule_count)
        else:
            append_rules.append(new_rules)

    rule_count_list = ', '.join(map(str, rule_count_list))

    return duplicates, rule_count_list, append_rules, duplicate_ips


def point_out_dupes(duplicates, duplicate_ips):
    returning = 'return_yaml.yaml'

    with open(os.getenv('filename'), 'r') as f:
        full_yaml_dict = yaml.safe_load(f)
        rule_blocks = full_yaml_dict.get('rules', [])

    with open(returning, 'w') as f:
        f.write("🚫 Duplicate Rules Detected:\n\n")
        for i, rule in enumerate(duplicates, start=1):
            ip_list = rule.get('source', {}).get('ips', []) or rule.get('destination', {}).get('ips', [])
            overlapping_ips = [ip for ip in ip_list if ip in duplicate_ips]

            proto = rule.get('protocol')
            port = rule.get('port')
            appid = rule.get('appid')
            url = rule.get('url')

            f.write(f"🔁 Rule #{i} matches existing rule(s) based on:\n")
            f.write(f"   • IPs: {', '.join(overlapping_ips)}\n")
            f.write(f"   • Protocol: {proto}\n")
            f.write(f"   • Port: {port}\n")
            f.write(f"   • App ID: {appid}\n")
            f.write(f"   • URL: {url}\n\n")

            matched_idx = None
            for j, r in enumerate(rule_blocks):
                if (
                    r.get('protocol') == proto and
                    r.get('port') == port and
                    r.get('appid') == appid and
                    r.get('url') == url and
                    any(ip in r.get('source', {}).get('ips', []) + r.get('destination', {}).get('ips', []) for ip in overlapping_ips)
                ):
                    matched_idx = j
                    break

            if matched_idx is not None:
                f.write(f"(Matching rule index in policy: #{matched_idx + 1})\n")
                block_lines = yaml.dump(rule_blocks[matched_idx], sort_keys=False).splitlines()
                for line in block_lines:
                    prefix = ">> " if any(k in line for k in overlapping_ips + [str(port), proto, appid, url]) else "   "
                    f.write(f"{prefix}{line}\n")
                f.write("   ---\n")
            else:
                f.write("⚠ Could not find matching rule block in parsed YAML.\n")

            f.write("\n")

    with open(returning) as readfile:
        print(readfile.read())

    return returning


def append_new_rules(new_rules_to_add, yaml_dict):
    for rules in new_rules_to_add:
        yaml_dict['rules'].append(rules)
    return yaml_dict


def get_file_contents(repo, file, token):
    local_paths = [
        f'tests/policies/{file}',
        f'policies/{file}',
    ]
    for path in local_paths:
        if os.path.exists(path):
            with open(path, 'r') as f:
                return yaml.safe_load(f)
    print(f"❌ Could not find existing policy file: {file}")
    return None


def run_tests():
    test_files_no_existing = [
        'tests/requests/good-request-policyv1.yaml',
        'tests/requests/good-request-policy.yaml',
        'tests/requests/bad-request-duplicates-within-policy.yaml',
        'tests/requests/bad-request-duplicates-within-policyv1.yaml',
        'tests/requests/bad-request-duplicates-within-policyv2.yaml'
    ]

    test_files_with_existing = [
        'tests/requests/bad-request-duplicates-with-existing-policyv2.yaml',
        'tests/requests/bad-request-duplicates-with-existing-policy.yaml'
    ]

    existing_policy_file = 'policies/existing-policy.yaml'

    for test_file in test_files_no_existing:
        print(f"\n🧪 Testing {test_file} (no existing policy match)")
        os.environ['filename'] = test_file
        os.environ['existing_policy'] = 'noop.txt'
        update_existing_policy()

    for test_file in test_files_with_existing:
        print(f"\n🧪 Testing {test_file} (with existing policy match)")
        os.environ['filename'] = test_file
        os.environ['existing_policy'] = 'existing.txt'

        with open('existing.txt', 'w') as f:
            f.write('existing-policy.yaml\n')

        os.makedirs('policies', exist_ok=True)
        with open(existing_policy_file, 'r') as src, open('policies/existing-policy.yaml', 'w') as dst:
            dst.write(src.read())

        update_existing_policy()


def main():
    run_tests()


if __name__ == "__main__":
    main()
