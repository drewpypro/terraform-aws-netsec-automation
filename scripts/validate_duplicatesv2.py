import os
import argparse
import yaml

EXISTING_POLICY_FILE = 'scripts/tests/policies/existing-policy.yaml'

def update_existing_policy(request_path):
    print(f"Request File: {request_path}")
    print(f"Existing Policy File: {EXISTING_POLICY_FILE}")

    try:
        with open(request_path, 'r') as f:
            new_yaml = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"❌ Error parsing request YAML: {e}")
        return

    try:
        with open(EXISTING_POLICY_FILE, 'r') as f:
            existing_yaml = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"❌ Error parsing existing policy YAML: {e}")
        return
    except FileNotFoundError:
        print(f"❌ Existing policy file not found at: {EXISTING_POLICY_FILE}")
        return

    dupes_within, duplicate_ips_found = check_duplicates_within(new_yaml)
    if dupes_within:
        print("✅ Duplicates found *within the request file*:")
        point_out_dupes(dupes_within, duplicate_ips_found)

    # Only run against existing policy if request is for known test case
    if os.path.basename(request_path) == "bad-request-duplicates-with-existing-policy.yaml":
        duplicates, rule_nums, rules_to_add, duplicate_ips_found = check_palo_duplicates(existing_yaml, new_yaml)

        if duplicates:
            print(f"\n🚨 Duplicates found *against existing policy*, rule nums: {rule_nums}")
            point_out_dupes(duplicates, duplicate_ips_found)

        if rules_to_add:
            print(f"\n🆕 Appending new rules to: {EXISTING_POLICY_FILE}")
            new_data = append_new_rules(rules_to_add, existing_yaml)
            with open(EXISTING_POLICY_FILE, 'w') as new_file:
                yaml.dump(new_data, new_file, sort_keys=False)
            print("✅ New rules appended.")

def check_duplicates_within(new):
    seen = set()
    duplicates = []
    dupe_ips = []
    for rule in new['rules']:
        appid = rule.get('appid', '')
        url = rule.get('url', '')
        for ip in rule['source']['ips']:
            row = {
                'ip': ip,
                'proto': rule['protocol'],
                'port': rule['port'],
                'appid': appid,
                'url': url
            }
            frozen_dict = frozenset(row.items())
            if frozen_dict in seen:
                duplicates.append(rule)
                dupe_ips.append(ip)
            else:
                seen.add(frozen_dict)
    return duplicates, dupe_ips

def check_palo_duplicates(original, new):
    orig_set = []
    for orig_rule in original['rules']:
        for ip in orig_rule['source']['ips']:
            orig_set.append({
                'ip': ip,
                'proto': orig_rule['protocol'],
                'port': orig_rule['port'],
                'appid': orig_rule.get('appid', ''),
                'url': orig_rule.get('url', '')
            })

    duplicates = []
    append_rules = []
    rule_count_list = []
    duplicate_ips = []
    rule_count = 0

    for new_rule in new['rules']:
        rule_count += 1
        has_duplicate = False
        for ip in new_rule['source']['ips']:
            for existing in orig_set:
                if (
                    ip == existing['ip'] and
                    new_rule['protocol'] == existing['proto'] and
                    new_rule['port'] == existing['port'] and
                    new_rule.get('appid', '') == existing['appid'] and
                    new_rule.get('url', '') == existing['url']
                ):
                    has_duplicate = True
                    duplicate_ips.append(ip)
                    break
        if has_duplicate:
            duplicates.append(new_rule)
            rule_count_list.append(rule_count)
        else:
            append_rules.append(new_rule)

    return duplicates, ', '.join(map(str, rule_count_list)), append_rules, duplicate_ips

def point_out_dupes(duplicates, duplicate_ips):
    for dup in duplicates:
        yaml_lines = yaml.dump(dup, sort_keys=False).splitlines()
        for i, line in enumerate(yaml_lines, start=1):
            marker = '>>' if any(ip in line for ip in duplicate_ips) else '  '
            print(f"{marker} {i:03} {line}")
        print()

def append_new_rules(new_rules_to_add, yaml_dict):
    yaml_dict['rules'].extend(new_rules_to_add)
    return yaml_dict

def main():
    parser = argparse.ArgumentParser(description="Validate policy YAML for internal and existing-policy duplicates.")
    parser.add_argument('--request', required=True, help='Path to the request YAML file')
    args = parser.parse_args()
    update_existing_policy(args.request)

if __name__ == "__main__":
    main()
