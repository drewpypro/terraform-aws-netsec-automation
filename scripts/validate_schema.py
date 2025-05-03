#!/usr/bin/env python3
import sys
import yaml
import json
import jsonschema

def load_yaml_file(path):
    with open(path, 'r') as f:
        return yaml.safe_load(f)

def load_json_file(path):
    with open(path, 'r') as f:
        return json.load(f)

def main():
    if len(sys.argv) != 3:
        print("Usage: validate_schema.py <yaml_file> <schema_file>")
        sys.exit(1)

    yaml_file = sys.argv[1]
    schema_file = sys.argv[2]

    try:
        data = load_yaml_file(yaml_file)
        schema = load_json_file(schema_file)

        if not isinstance(data, list):
            print("❌ Top-level YAML is not a list (array), but schema expects one.")
            sys.exit(1)

        jsonschema.validate(instance=data, schema=schema)
        print("✅ Schema validation passed")
    except jsonschema.exceptions.ValidationError as ve:
        print("❌ Schema validation failed:")
        print(json.dumps(ve.schema, indent=2))
        print(ve.message)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
