#!/usr/bin/env python3
import sys
import yaml
import json
import jsonschema
from jsonschema.exceptions import ValidationError

def load_yaml_file(path):
    with open(path, 'r') as f:
        content = f.read()
    try:
        # Use safe_load_all to handle multiple documents
        docs = list(yaml.safe_load_all(content))
        return docs, content.splitlines()
    except yaml.YAMLError as e:
        print("❌ YAML parsing failed:\n")
        if hasattr(e, 'problem_mark'):
            mark = e.problem_mark
            line = mark.line
            print_context(line, content.splitlines(), "YAML syntax error")
        else:
            print(str(e))
        sys.exit(1)

def load_json_file(path):
    with open(path, 'r') as f:
        return json.load(f)

def print_context(line_num, lines, error_msg):
    start = max(line_num - 1, 0)
    end = min(line_num + 2, len(lines))

    print(f"Error: {error_msg}")
    print("Problem:")
    print("```yaml")
    for i in range(start, end):
        prefix = ">> " if i == line_num else "   "
        print(f"{prefix}{i + 1:03}: {lines[i]}")
    print("```")
    print("")

def main():
    if len(sys.argv) != 3:
        print("Usage: validate_schema.py <yaml_file> <schema_file>")
        sys.exit(1)

    yaml_file = sys.argv[1]
    schema_file = sys.argv[2]

    docs, data_lines = load_yaml_file(yaml_file)
    schema = load_json_file(schema_file)

    validator = jsonschema.Draft7Validator(schema)
    all_errors = []

    # Validate each document
    for i, doc in enumerate(docs, 1):
        errors = list(validator.iter_errors(doc))
        if errors:
            print(f"❌ Document {i} failed schema validation:\n")
            for error in errors:
                print(f"  - {error.message}")
            all_errors.extend(errors)

    if all_errors:
        sys.exit(1)

    print("✅ All documents passed schema validation")

if __name__ == "__main__":
    main()