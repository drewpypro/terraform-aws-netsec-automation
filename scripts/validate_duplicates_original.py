import base64
import os
import requests
import yaml


def update_existing_policy():
    existing_policy = os.getenv('existing_policy')
    created_yaml = os.getenv('filename')
    print(created_yaml)

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
        return print(f"Error parsing YAML: {e}")

    if 'policies' in created_yaml:
        yaml_filename = created_yaml.replace('policies/', '')

    duplicates_within, duplicate_ips_found = check_duplicates_within(new_yaml, ip_direction_key)
    if len(duplicates_within) !=0:
        with open(os.environ.get('GITHUB_OUTPUT'), 'a') as fh:
            fh.write(f'duplicates_within={duplicates_within}\n')

    file_found_count = 0
    with open(existing_policy) as f:
        files = f.readlines()
        for file in files:
            file = file.replace('\n', '')
            if yaml_filename == file:
                file_found_count += 1
                found_file = yaml_filename
                print(f'found same file: {found_file}')

                original_yaml = get_file_contents(repo, found_file, token)


                duplicates, rule_nums, rules_to_add, duplicate_ips_found = check_duplicates(original_yaml, new_yaml, ip_direction_key)

                if len(duplicates) !=0:
                    pointer_yaml = point_out_dupes(duplicates, duplicate_ips_found)
                    with open(os.environ.get('GITHUB_OUTPUT'), 'a') as fh:
                        fh.write(f'duplicates={pointer_yaml}\n')
                        fh.write(f'rule_nums={rule_nums}\n')

                if len(rules_to_add) !=0:
                    new_data = append_new_rules(rules_to_add, original_yaml)
                    with open(f'policies/{found_file}', 'w') as new_file:
                        yaml.dump(new_data, new_file, sort_keys=False)
                        new_file.close()
                        print(f'New Rules Appended to {found_file}')
    
    if file_found_count == 0:
        print("File doesn't match existing files")
        return

def check_duplicates_within(new, ip_direction_key):
    rows = []
    seen = set()
    duplicates = []
    dupe_ips = []
    duplicate_ips_within_rule = []

    for rule_idx, rules in enumerate(new['rules']):
        # 🟡 Detect duplicate IPs within a single rule
        ips = rules[ip_direction_key]['ips']
        seen_ips = set()
        for ip in ips:
            if ip in seen_ips:
                duplicate_ips_within_rule.append((rule_idx + 1, ip))  # 1-based index
            seen_ips.add(ip)

        # 🔁 Check for full rule duplicates
        for ip in ips:
            row = {
                'ip': ip,
                'proto': rules['protocol'],
                'port': rules['port'],
                'appid': rules['appid'],
                'url': rules['url']
            }
            rows.append(row)
            frozen_dict = frozenset(row.items())
            if frozen_dict in seen:
                duplicates.append(rules)
                dupe_ips.append(ip)
            else:
                seen.add(frozen_dict)

    # 🟢 Print or log internal IP dupes
    if duplicate_ips_within_rule:
        print("⚠️ Duplicate IPs found **within** individual rule blocks:")
        for rule_num, ip in duplicate_ips_within_rule:
            print(f"   • Rule #{rule_num}: IP {ip} is listed more than once")

    return duplicates, dupe_ips

def check_duplicates(original, new, ip_direction_key):
    orig_set = []

    for orig_rules in original['rules']:
        for ip in orig_rules[ip_direction_key]['ips']:
            ip = ip
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
                if ip == set['ip'] and new_rules['protocol'] == set['proto'] and new_rules['port'] == set['port']:
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
    context_lines = 5

    with open('policies/' + os.getenv('filename'), 'r') as f:
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

            f.write("📄 Snippet from existing policy:\n")

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
    with open(f'policies/{file}', 'r') as f:
        return yaml.safe_load(f)


# def get_file_contents(repo, file, token):
#     url = f'https://github.com/api/v3/repos{repo}/contents/policies/{file}'
#     session = requests.session()

#     headers = {
#         "Accept": "application/vnd.github+json",
#         "Authorization": f"token {token}"
#     }

#     try: 
#         _req = session.get(url, headers=headers)
#         data = _req.json()
#         yaml_content = data['content']
#         yaml_parse = base64.b64decode(yaml_content)
#         yaml_str = yaml_parse.decode('utf-8') 
#         parsed_yaml = yaml.safe_load(yaml_str)

#         return parsed_yaml
#     except Exception as e:
#         return e

def main():
    update_existing_policy()

if __name__ == "__main__":
    main()