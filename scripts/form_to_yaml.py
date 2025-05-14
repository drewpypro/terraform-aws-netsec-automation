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
    # Look for YAML in code blocks
    yaml_pattern = r"```yaml\s*(.*?)```"
    matches = re.findall(yaml_pattern, body, re.DOTALL)
    
    if not matches:
        log_debug("No YAML code blocks found in the issue body")
        return None
    
    # Combine all YAML matches
    full_yaml = '\n---\n'.join(matches)
    log_debug(f"Extracted YAML:\n{full_yaml}")
    
    return full_yaml

def is_form_submission(body, labels):
    """Determine if this is a form submission requiring processing"""
    # Check for form-specific indicators
    form_indicators = [
        "YOUR-REQUEST-ID",
        "YOUR-BUSINESS JUSTIFICATION HERE",
        "YOUR-SERVICE-NAME",
        "YOUR-THIRD-PARTY-NAME"
    ]
    
    # Check for placeholders in the YAML
    form_detected = any(indicator in body for indicator in form_indicators)
    
    # Check labels
    form_labels = ["privatelink-consumer", "privatelink-provider"]
    is_form_label = any(label in labels for label in form_labels)
    
    return form_detected and is_form_label

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
        
        # Determine if this is a form submission requiring processing
        if not is_form_submission(body, labels):
            log_debug("Not a form submission. Extracting YAML directly.")
            yaml_text = extract_yaml_from_body(body)
            
            if not yaml_text:
                log_debug("No YAML found in the issue body")
                sys.exit(1)
            
            # Simply copy the YAML to the output file
            with open("/tmp/issue.yaml", "w") as f:
                f.write(yaml_text)
            
            # Determine request type from labels
            request_type = "consumer" if "privatelink-consumer" in labels else "provider"
            
            log_debug("YAML copied directly from issue")
            print(f"request_type={request_type}")
            print("YAML copied from code block")
            sys.exit(0)
        
        # Process form submission (existing logic)
        # ... (rest of the existing form processing logic)

    except Exception as e:
        log_debug(f"Unexpected error: {e}")
        log_debug(traceback.format_exc())
        print("Error processing issue form")
        sys.exit(1)

if __name__ == "__main__":
    main()