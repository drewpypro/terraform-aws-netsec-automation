#!/usr/bin/env python3
import json
import sys
import os
import re
import traceback
import yaml

def setup_logging():
    """Set up logging to write debug information to a file"""
    log_file = "/tmp/form_to_yaml_debug.log"
    sys.stderr = open(log_file, 'w')
    print(f"Starting script execution. Current working directory: {os.getcwd()}", file=sys.stderr)
    print(f"GITHUB_EVENT_PATH: {os.environ.get('GITHUB_EVENT_PATH')}", file=sys.stderr)

def log_debug(message):
    """Log debug messages to stderr"""
    print(message, file=sys.stderr)
    sys.stderr.flush()

def extract_yaml_from_body(body):
    """Extract YAML from issue body"""
    # Look for code blocks with YAML
    yaml_pattern = r"```yaml\s*(.*?)```"
    matches = re.findall(yaml_pattern, body, re.DOTALL)
    
    if not matches:
        log_debug("No YAML code blocks found in the issue body")
        return None
    
    # Combine all YAML matches
    full_yaml = '\n---\n'.join(matches)
    log_debug(f"Extracted YAML:\n{full_yaml}")
    
    return full_yaml

def validate_yaml_structure(yaml_docs):
    """Validate the structure of YAML documents"""
    for doc in yaml_docs:
        # Check for required top-level keys
        if not all(key in doc for key in ['security_group', 'rules']):
            log_debug(f"Invalid YAML document: missing required keys")
            return False
        
        # Additional validation can be added here
    return True

def process_yaml_documents(yaml_docs):
    """Process multiple YAML documents"""
    processed_docs = []
    
    for doc in yaml_docs:
        # Validate document structure
        security_group = doc.get('security_group', {})
        rules = doc.get('rules', [])
        
        # Basic validation
        if not security_group or not rules:
            log_debug("Skipping invalid document")
            continue
        
        # Extract common fields
        processed_doc = {
            'security_group': {
                'request_id': security_group.get('request_id', ''),
                'business_justification': security_group.get('business_justification', ''),
                'accountId': security_group.get('accountId', '6666666'),
                'region': security_group.get('region', ''),
                'vpc_id': security_group.get('vpc_id', ''),
                'serviceType': security_group.get('serviceType', ''),
                'serviceName': security_group.get('serviceName', ''),
                'thirdpartyName': security_group.get('thirdpartyName', ''),
                'thirdPartyID': security_group.get('thirdPartyID', '')
            },
            'rules': []
        }
        
        # Process rules
        for rule in rules:
            processed_rule = {
                'request_id': rule.get('request_id', ''),
                'business_justification': rule.get('business_justification', ''),
                'source': {
                    'account_id': rule.get('source', {}).get('account_id', ''),
                    'vpc_id': rule.get('source', {}).get('vpc_id', ''),
                    'region': rule.get('source', {}).get('region', ''),
                    'ips': rule.get('source', {}).get('ips', [])
                },
                'protocol': rule.get('protocol', ''),
                'port': rule.get('port', ''),
                'appid': rule.get('appid', ''),
                'url': rule.get('url', ''),
                'enable_palo_inspection': rule.get('enable_palo_inspection', False)
            }
            processed_doc['rules'].append(processed_rule)
        
        processed_docs.append(processed_doc)
    
    return processed_docs

def main():
    try:
        # Set up logging
        setup_logging()

        # Load GitHub event data
        event_path = os.environ.get("GITHUB_EVENT_PATH")
        log_debug(f"Event path: {event_path}")

        if not event_path or not os.path.exists(event_path):
            log_debug(f"Error: Event path {event_path} does not exist")
            print("Error: Unable to find GitHub event file")
            sys.exit(1)

        try:
            with open(event_path, 'r') as f:
                event = json.load(f)
        except Exception as e:
            log_debug(f"Error reading event file: {e}")
            log_debug(traceback.format_exc())
            sys.exit(1)
        
        # Extract issue body and labels
        body = event["issue"]["body"]
        log_debug("Issue body extracted")
        
        labels = [label["name"] for label in event.get("issue", {}).get("labels", [])]
        log_debug(f"Labels: {labels}")
        
        # Determine request type
        request_type = None
        if "privatelink-consumer" in labels:
            request_type = "consumer"
        elif "privatelink-provider" in labels:
            request_type = "provider"
        
        log_debug(f"Request type: {request_type}")
        
        # Extract YAML from body
        yaml_text = extract_yaml_from_body(body)
        
        if not yaml_text:
            log_debug("No YAML found in the issue body")
            sys.exit(1)
        
        # Parse YAML documents
        try:
            yaml_docs = list(yaml.safe_load_all(yaml_text))
        except yaml.YAMLError as e:
            log_debug(f"YAML parsing error: {e}")
            sys.exit(1)
        
        # Validate YAML structure
        if not validate_yaml_structure(yaml_docs):
            log_debug("YAML structure validation failed")
            sys.exit(1)
        
        # Process YAML documents
        processed_docs = process_yaml_documents(yaml_docs)
        
        # Write processed documents to file
        with open("/tmp/issue.yaml", "w") as f:
            yaml.safe_dump_all(processed_docs, f, default_flow_style=False, indent=2)
        
        log_debug("YAML file generated successfully")
        print(f"request_type={request_type}")
        print(f"documents_count={len(processed_docs)}")
        print("YAML processed from code block")

    except Exception as e:
        log_debug(f"Unexpected error: {e}")
        log_debug(traceback.format_exc())
        print("Error processing issue form")
        sys.exit(1)

if __name__ == "__main__":
    main()