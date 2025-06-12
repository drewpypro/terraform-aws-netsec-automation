
#!/usr/bin/env python3
import json
import yaml
import sys

DB_PATH = 'thirdpartyDBconfigName.json'
YAML_PATH = 'request.yaml'

def load_db():
    with open(DB_PATH, 'r') as f:
        return json.load(f)

def load_yaml():
    with open(YAML_PATH, 'r') as f:
        return yaml.safe_load(f)

def validate_thirdparty(thirdparty_name, thirdparty_id, db):
    for entry in db:
        if str(entry['thirdpartyID']) == str(thirdparty_id) and entry['thirdpartyconfigname'].lower() == thirdparty_name.lower():
            return entry
    return None

def main():
    db = load_db()
    data = load_yaml()

    sg = data.get("security_group", {})
    name = sg.get("thirdpartyName")
    tpid = sg.get("thirdPartyID")

    if not name or not tpid:
        print("Missing thirdpartyName or thirdPartyID")
        sys.exit(1)

    result = validate_thirdparty(name, tpid, db)

    if not result:
        print(f"❌ thirdPartyID '{tpid}' and name '{name}' not found in third-party DB.")
        sys.exit(1)

    if result['contract_status'] != 'valid':
        print(f"❌ Contract status for '{name}' is '{result['contract_status']}'. Connectivity should not be granted.")
        print("```json")
        print(json.dumps(result, indent=2))
        print("```")
        sys.exit(1)
        
    if result['security_risk'] in ['high', 'critical']:
        print(f"⚠️ Security risk for '{name}' is '{result['security_risk']}'. Requires manual review before proceeding.")
        sys.exit(1)

    print(f"✅ Third-party '{name}' (ID: {tpid}) is valid with acceptable contract and risk level.")

if __name__ == "__main__":
    main()
