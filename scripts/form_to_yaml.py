#!/usr/bin/env python3
import json
import sys
import os
import re
import traceback

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

def extract_field(body, field_name):
    """Extract a field value from the GitHub issue body"""
    log_debug(f"Extracting field: {field_name}")
    pattern = r"### " + re.escape(field_name) + r"\s*\n(.*?)(?=\n###|\Z)"
    match = re.search(pattern, body, re.DOTALL)
    if match:
        value = match.group(1).strip()
        log_debug(f"Field {field_name} value: {value}")
        return value
    log_debug(f"No value found for field: {field_name}")
    return ""

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
        
        # Check if this is already a YAML template
        if "```yaml" in body:
            # Extract YAML directly
            yaml_pattern = r"```yaml\s*(.*?)\s*```"
            match = re.search(yaml_pattern, body, re.DOTALL)
            if match:
                with open("/tmp/issue.yaml", "w") as f:
                    f.write(match.group(1))
                print(f"request_type={request_type}")
                print("YAML extracted directly from code block")
                log_debug("YAML extracted from code block")
                return
        
        # Otherwise, treat as a form and convert to YAML
        # Extract common fields
        region = extract_field(body, "AWS Region")
        
        # Extract VPC ID and remove region info in parentheses if present
        vpc_id = extract_field(body, "VPC ID")
        vpc_id = re.sub(r"\s*\(.*\)$", "", vpc_id)
        
        request_id = extract_field(body, "Request ID")
        business_justification = extract_field(body, "Business Justification")
        
        # Validate request type
        if request_type is None:
            log_debug("Error: Unable to determine request type")
            print("Unknown request type")
            sys.exit(1)
        
        # Generate YAML based on request type
        if request_type == "consumer":
            # Extract consumer-specific fields
            third_party_name = extract_field(body, "Third-Party Name")
            third_party_id = extract_field(body, "Third-Party ID")
            service_name = extract_field(body, "VPC Endpoint Service Name")
            source_account_id = extract_field(body, "Source Account ID")
            source_vpc_id = extract_field(body, "Source VPC ID")
            source_region = extract_field(body, "Source Region")
            
            # Extract IPs (one per line)
            source_ips = extract_field(body, "Source IP Addresses")
            ips = [ip.strip() for ip in source_ips.split("\n") if ip.strip()]
            
            protocol = extract_field(body, "Protocol")
            port = extract_field(body, "Port Number")
            appid = extract_field(body, "Application ID")
            url = extract_field(body, "Service URL")
            enable_palo = extract_field(body, "Enable Palo Alto Inspection")
            
            # Generate YAML
            yaml = f"""security_group:
  request_id: {request_id}
  business_justification: >
    {business_justification}
  accountId: 6666666
  region: {region}
  vpc_id: {vpc_id}
  serviceType: privatelink-consumer
  serviceName: {service_name}
  thirdpartyName: {third_party_name}
  thirdPartyID: {third_party_id}
rules:
  - request_id: {request_id}
    business_justification: >
      {business_justification}
    source:
      account_id: {source_account_id}
      vpc_id: {source_vpc_id}
      region: {source_region}
      ips:
"""
            for ip in ips:
                yaml += f"        - {ip}\n"
            
            yaml += f"""    protocol: {protocol}
    port: {port}
    appid: {appid}
    url: {url}
    enable_palo_inspection: {enable_palo}
"""
            
        elif request_type == "provider":
            # Extract provider-specific fields
            internal_app_id = extract_field(body, "Internal App ID")
            service_name = extract_field(body, "Service Name")
            
            # Extract IPs (one per line)
            destination_ips = extract_field(body, "Destination IP Addresses")
            ips = [ip.strip() for ip in destination_ips.split("\n") if ip.strip()]
            
            protocol = extract_field(body, "Protocol")
            port = extract_field(body, "Port Number")
            appid = extract_field(body, "Application ID")
            url = extract_field(body, "Service URL")
            enable_palo = extract_field(body, "Enable Palo Alto Inspection")
            
            # Generate YAML
            yaml = f"""security_group:
  request_id: {request_id}
  business_justification: >
    {business_justification}
  accountId: 6666666
  region: {region}
  vpc_id: {vpc_id}
  serviceType: privatelink-provider
  serviceName: {service_name}
  internalAppID: {internal_app_id}
rules:
  - request_id: {request_id}
    business_justification: >
      {business_justification}
    destination:
      ips:
"""
            for ip in ips:
                yaml += f"        - {ip}\n"
            
            yaml += f"""    protocol: {protocol}
    port: {port}
    appid: {appid}
    url: {url}
    enable_palo_inspection: {enable_palo}
"""
        
        # Write YAML to file
        with open("/tmp/issue.yaml", "w") as f:
            f.write(yaml)
        
        log_debug("YAML file generated successfully")
        print(f"request_type={request_type}")
        print("YAML generated from form fields")

    except Exception as e:
        log_debug(f"Unexpected error: {e}")
        log_debug(traceback.format_exc())
        print("Error processing issue form")
        sys.exit(1)

if __name__ == "__main__":
    main()