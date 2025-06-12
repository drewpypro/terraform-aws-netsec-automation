
#!/usr/bin/env python3

import sys
import yaml
import json

# Default paths – these should be overridden when used in GitHub Actions or CLI
YAML_PATH = 'request.yaml'
DB_PATH = 'thirdpartyDBconfigName.json'

def load_yaml_file(path):
    """Load the YAML file for the security group request"""
    with open(path, 'r') as f:
        return yaml.safe_load(f)

def load_json_file(path):
    """Load the JSON file containing the third-party database"""
    with open(path, 'r') as f:
        return json.load(f)

def print_json_block(entry):
    """Print JSON block in markdown format for GitHub Issues"""
    print("```json")
    print(json.dumps(entry, indent=2))
    print("```\n")

def validate_thirdparty(thirdparty_name, thirdparty_id, db):
    """Match thirdpartyName and thirdPartyID to DB entry using normalized name"""
    for entry in db:
        if (
            str(entry.get("thirdpartyID")) == str(thirdparty_id)
            and entry.get("thirdpartyconfigname", "").lower() == thirdparty_name.lower()
        ):
            return entry
    return None

def main():
    if len(sys.argv) != 3:
        print("Usage: validate_thirdparty.py <yaml_file> <thirdpartydb.json>")
        sys.exit(1)

    yaml_file = sys.argv[1]
    db_file = sys.argv[2]

    # Load inputs
    try:
        request = load_yaml_file(yaml_file)
        db = load_json_file(db_file)
    except Exception as e:
        print(f"❌ Failed to load files: {e}")
        sys.exit(1)

    sg = request.get("security_group", {})
    name = sg.get("thirdpartyName")
    tpid = sg.get("thirdPartyID")

    if not name or not tpid:
        print("❌ Missing 'thirdpartyName' or 'thirdPartyID' in YAML")
        sys.exit(1)

    # Perform match
    result = validate_thirdparty(name, tpid, db)
    if not result:
        print(f"❌ No match found in third-party DB for name '{name}' and ID '{tpid}'")
        sys.exit(1)

    # Reject if contract is not valid
    if result.get("contract_status") != "valid":
        print(f"❌ Contract for '{name}' is not valid (status: '{result.get('contract_status')}').")
        print_json_block(result)
        sys.exit(1)

    # Warn if security risk is high or critical
    if result.get("security_risk") in ["high", "critical"]:
        print(f"⚠️ Security risk for '{name}' is '{result.get('security_risk')}'. Manual review required.")
        print_json_block(result)
        sys.exit(1)

    # Success
    print(f"✅ Third-party '{name}' (ID: {tpid}) is valid with acceptable contract and risk level.")

if __name__ == "__main__":
    main()
