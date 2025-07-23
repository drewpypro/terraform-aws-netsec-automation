import os
import sys
import yaml
from collections import defaultdict

def load_yaml_file(filepath):
    with open(filepath, "r") as f:
        return yaml.safe_load(f)

def format_rule_yaml(rule, ip_direction_key, highlight_ips=None, highlight_all_fields=False):
    lines = []
    lines.append(f"    - request_id: {rule.get('request_id')}")
    lines.append(f"      {ip_direction_key}:")
    lines.append(f"        ips:")
    for nip in rule[ip_direction_key]['ips']:
        if highlight_all_fields or (highlight_ips and nip in highlight_ips):
            lines.append(f">>          - {nip}")
        else:
            lines.append(f"            - {nip}")
    for key in ['protocol', 'port', 'appid', 'url']:
        value = rule.get(key)
        if highlight_all_fields:
            lines.append(f">>      {key}: {value}")
        else:
            lines.append(f"        {key}: {value}")
    return "\n".join(lines)

def extract_5tuple(rule, ip_direction_key):
    keys = []
    for ip in rule[ip_direction_key]["ips"]:
        keys.append((
            ip,
            rule["protocol"],
            str(rule["port"]),
            rule["appid"],
            rule["url"]
        ))
    return keys

def full_tuple_key(rule, ip_direction_key):
    return (
        tuple(rule[ip_direction_key]["ips"]),
        rule["protocol"],
        str(rule["port"]),
        rule["appid"],
        rule["url"]
    )

def check_duplicates_within_request(policy, ip_direction_key):
    rules = policy.get("rules", [])
    dupe_ip_map = defaultdict(set)
    dupe_full_tuple = set()
    found = False

    # Mapping: rule idx -> set of matching indices
    matches = defaultdict(set)

    # Track full tuple matches
    full_tuple_to_idxs = defaultdict(list)
    for idx, rule in enumerate(rules):
        key = full_tuple_key(rule, ip_direction_key)
        full_tuple_to_idxs[key].append(idx)
    for idxs in full_tuple_to_idxs.values():
        if len(idxs) > 1:
            found = True
            for i in idxs:
                for j in idxs:
                    if i != j:
                        matches[i].add(j)
                dupe_full_tuple.add(i)

    # Track partial (IP-level) dupes
    tuple_to_rules = defaultdict(list)
    for idx, rule in enumerate(rules):
        for ip in rule[ip_direction_key]["ips"]:
            tup = (ip, rule["protocol"], str(rule["port"]), rule["appid"], rule["url"])
            tuple_to_rules[tup].append(idx)
    for tup, idxs in tuple_to_rules.items():
        if len(idxs) > 1:
            found = True
            for i in idxs:
                for j in idxs:
                    if i != j:
                        matches[i].add(j)
                dupe_ip_map[i].add(tup[0])

    if found:
        out = ["🏛️ Duplicates detected in submitted policy\n"]
        already_output = set()
        for idx in range(len(rules)):
            if idx in already_output:
                continue
            highlight_all = idx in dupe_full_tuple
            highlight_ips = set(rules[idx][ip_direction_key]['ips']) if highlight_all else dupe_ip_map[idx]
            has_any_highlight = highlight_all or highlight_ips  # either full or partial

            if idx in matches and matches[idx]:
                match_indices = sorted(matches[idx])
                header = (
                    f"# Submitted policy rule index #{idx+1} matches submitted policy index "
                    + ", ".join([f"#{j+1}" for j in match_indices])
                )
                out.append(header)
            elif has_any_highlight:
                # Single-rule dupe (only itself)
                header = f"# Submitted policy rule index #{idx+1} (duplicate values within rule)"
                out.append(header)
            else:
                continue  # no match, no dupe, skip

            out.append("```yaml")
            out.append(format_rule_yaml(
                rules[idx],
                ip_direction_key,
                highlight_ips,
                highlight_all_fields=highlight_all
            ))
            out.append("```")
            already_output.add(idx)
        return True, "\n".join(out)
    return False, ""


def check_duplicates_against_existing(request_policy, existing_policy, ip_direction_key, existing_filename):
    existing_map = defaultdict(list)
    for idx, rule in enumerate(existing_policy.get("rules", [])):
        for key in extract_5tuple(rule, ip_direction_key):
            existing_map[key].append((idx, rule))

    existing_full_tuples = defaultdict(list)
    for idx, rule in enumerate(existing_policy.get("rules", [])):
        existing_full_tuples[full_tuple_key(rule, ip_direction_key)].append(idx)
    submitted_full_tuples = defaultdict(list)
    for idx, rule in enumerate(request_policy.get("rules", [])):
        submitted_full_tuples[full_tuple_key(rule, ip_direction_key)].append(idx)

    submitted_dupe = defaultdict(set)
    existing_dupe = defaultdict(set)
    submitted_blocks = set()
    existing_blocks = set()
    highlight_all_fields_sub = set()
    highlight_all_fields_exist = set()

    # NEW: Track which submitted rule matches which existing rule indices
    submitted_matches = defaultdict(set)  # <----- ADD THIS LINE

    for sub_key, sub_idxs in submitted_full_tuples.items():
        if sub_key in existing_full_tuples:
            for sidx in sub_idxs:
                highlight_all_fields_sub.add(sidx)
                submitted_blocks.add(sidx)
            for eidx in existing_full_tuples[sub_key]:
                highlight_all_fields_exist.add(eidx)
                existing_blocks.add(eidx)
            # NEW: mark full-tuple matches as matches for both sides
            for sidx in sub_idxs:
                for eidx in existing_full_tuples[sub_key]:
                    submitted_matches[sidx].add(eidx)  # <--- ADD THIS

    for req_idx, rule in enumerate(request_policy.get("rules", [])):
        for key in extract_5tuple(rule, ip_direction_key):
            if key in existing_map:
                submitted_dupe[req_idx].add(key[0])
                submitted_blocks.add(req_idx)
                for ex_idx, _ in existing_map[key]:
                    existing_dupe[ex_idx].add(key[0])
                    existing_blocks.add(ex_idx)
                    submitted_matches[req_idx].add(ex_idx)  # <--- ADD THIS

    if submitted_blocks or existing_blocks:
        out = [f"\n\n🏛️ Duplicates detected in existing policy {existing_filename}\n"]
        # Change: when printing each submitted rule, show which existing rule(s) it matches.
        for idx in sorted(submitted_blocks):
            rule = request_policy["rules"][idx]
            highlight_ips = set(rule[ip_direction_key]["ips"]) if idx in highlight_all_fields_sub else submitted_dupe[idx]
            highlight_all = idx in highlight_all_fields_sub
            # NEW: If there are matches, print them in the header.
            if idx in submitted_matches and submitted_matches[idx]:
                match_indices = ", ".join([f"#{i+1}" for i in sorted(submitted_matches[idx])])
                out.append(f"# Submitted policy rule index #{idx+1} matches existing policy rule index {match_indices}")
            else:
                out.append(f"# Submitted policy rule index #{idx+1}")
            out.append("```yaml")
            out.append(format_rule_yaml(
                rule,
                ip_direction_key,
                highlight_ips,
                highlight_all_fields=highlight_all
            ))
            out.append("```")
        for idx in sorted(existing_blocks):
            rule = existing_policy["rules"][idx]
            highlight_ips = set(rule[ip_direction_key]["ips"]) if idx in highlight_all_fields_exist else existing_dupe[idx]
            highlight_all = idx in highlight_all_fields_exist
            out.append(f"# Existing policy rule index #{idx+1}")
            out.append("```yaml")
            out.append(format_rule_yaml(
                rule,
                ip_direction_key,
                highlight_ips,
                highlight_all_fields=highlight_all
            ))
            out.append("```")
        return True, "\n".join(out)
    return False, ""

def main():
    request_file = os.getenv("filename") or (len(sys.argv) > 1 and sys.argv[1])
    existing_file = os.getenv("existing_policy") or (len(sys.argv) > 2 and sys.argv[2])

    if not request_file:
        print("Missing request policy filename (env var 'filename' or argv[1])")
        sys.exit(1)

    request_policy = load_yaml_file(request_file)
    service_type = request_policy["security_group"].get("serviceType", "")
    ip_direction_key = "source" if service_type == "privatelink-consumer" else "destination"

    # CHANGED: DO NOT exit after within-policy dupe. Print and keep going.
    has_within_dupe, within_output = check_duplicates_within_request(request_policy, ip_direction_key)
    if has_within_dupe:
        print(within_output)
        # DO NOT sys.exit(0); just keep going!

    # Check against existing policy (always, if provided)
    found_dupe = has_within_dupe  # keep track if any dupes found
    if existing_file:
        existing_policy = load_yaml_file(existing_file)
        has_ext_dupe, ext_output = check_duplicates_against_existing(
            request_policy, existing_policy, ip_direction_key, existing_file
        )
        if has_ext_dupe:
            print(ext_output)
            found_dupe = True

    if not found_dupe:
        print("💦 No Duplicates detected!")


if __name__ == "__main__":
    main()
