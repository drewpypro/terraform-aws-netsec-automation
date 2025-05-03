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
        data = yaml.safe_load(content)
        return data, content.splitlines()
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

def find_error_line(data_lines, error_path):
    # Try to match the deepest key in the path to a line in the YAML text
    keys = [str(k) for k in error_path if not isinstance(k, int)]
    for i, line in enumerate(data_lines):
        if any(k in line for k in keys[-1:]):
            return i
    return None

def main():
    if len(sys.argv) != 3:
        print("Usage: validate_schema.py <yaml_file> <schema_file>")
        sys.exit(1)

    yaml_file = sys.argv[1]
    schema_file = sys.argv[2]

    data, data_lines = load_yaml_file(yaml_file)
    schema = load_json_file(schema_file)

    validator = jsonschema.Draft7Validator(schema)
    errors = list(validator.iter_errors(data))

    if not errors:
        print("✅ Schema validation passed")
        return

    print("❌ Schema validation failed:\n")
    for error in errors:
        line = find_error_line(data_lines, error.path) or 0
        print_context(line, data_lines, error.message)

    sys.exit(1)

if __name__ == "__main__":
    main()
