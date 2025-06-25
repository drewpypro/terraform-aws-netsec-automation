# locals.tf
- locals.tf is a TF preprocessor that ingests policy YAML from a git issues pipeline and builds structured objects for AWS security-groups and Palo Alto security policy creation. 
- YAML policy files define security group and Palo Alto rules. Terraform loads these policies, expands each rule per CIDR, groups and deduplicates the rules, and builds structured inputs per region. 
- Modules consume the preprocessed data avoiding runtime failures and ensuring consistent outputs. 

## Goals 
- Modular logic
- Multi-dimensional grouping
- Deduplication to prevent failures
- Compatible config values for both Palo Alto and AWS SG controls.

## Purpose
- Create AWS Security-groups and rules for thirdparty-usecase. 
- Create Palo Alto Panorama security rules, service objects, tags and URL categories. 
- Pre-process and flatten rule data for each policy.rules entry, then deduplicate and group the rules based on key attributes, organized per AWS region. 

## Inputs
 - Each policy yaml file contains: 
    - security_group: Metadata for SG creation
    - rules[]: List of required access that needs to be built on AWS SG's and Palo Alto firewall rules. 

## Logic Flow
1. Load Yaml files
    ```
    policy_files = fileset(...)
    policies = { for file in policy_files : ...yamldecode(...) }
    ```
    - Reads all *-policy.yaml files
    - Parses them into usable Terraform Objects. 
2. Filter policies
    ```
    consumer_policies = { ... if serviceType == "privatelink-consumer" }
    provider_policies = { ... if serviceType == "privatelink-provider" }
    ```
    - Separates consumer vs. provider Privatelink service type requests. 
3. Flatten AWS SG rules
    ```
    consumer_rule_combinations = flatten([... for policy.rules : for source.ip : {...}])
    ```
    - Each rule is expanded per Source IP, resulting in the following structure. 
        ```
        {
            key        = "Datadog-us-east-1-tcp-443-10.11.1.1/32-0-0"
            dedup_key  = "Datadog-us-east-1-tcp-443-10.11.1.1/32"
            sg_key     = "Datadog-us-east-1"
            ...
        }
        ```
    - 2 rules x 3 source IPs = 6 unique ```consumer_rule_combinations```. 
4. Build Palo Alto groupings
    - initial expansion
        ```
        consumer_palo_rule_combinations = flatten([...])
        ```
    - each rule is grouped by a palo_key based on ```protocol + port + appid + url```: 
        ```
        palo_key = "Datadog-us-east-1-tcp-443-ssl-api.datadoghq.com"
        ```
    - multiple entries for the same palo_key are merged under ```source_ips[]``` in ```consumer_palo_grouped_rules``` 
    - group by SG and Palo Key
        ```
        consumer_palo_grouped_rules = {
        region => {
            sg_key => {
            palo_key => {
                protocol, port, appid, url, source_ips[]
                    }
                }
            }
        }
        ```
        - Deduplicates Palo rules by grouping them under SGs per region. 
        - Aggregates all source_ips targeting same protocol/appid/URL.
5. Deduplicate AWS rules
    ```
    consumer_aws_rules_deduped = {
        dedup_key => combo[0]
    }
    ```
    - Removes redundant CIDR+port/protocol rules
    - Only one rule per unique CIDR/protocol/port.
6. Group per region and SG
    ```
    consumer_sgs_by_region = {
        region => {
            sg_key => {
            sg_name
            vpc_id
            aws_rules { ... }
            palo_rules { ... }
            }
        }
    }
    ```
    - Master grouping that ties everything together 
    - Feeds directly into module.consumer_sg_*
    - This is the final structure that main.tf uses to deploy modules using for loops. 

## Output
- Each SG Module receives: 
    - aws_rules: Fully deduped, precompiled rule objects
    - palo_rules: Pre-grouped objects for Palo Alto config
    - Metadata: Tags, SG Names.

## Sample Request Logic Flow
- The following request is filtered and loaded into the logic for ```privatelink-consumer``` 
    ```yaml
    security_group:
    request_id: RQ-001
    business_justification: >
        Create security-group for datadog API us-east-1 privatelink in us-east-1
    accountId: 6666666
    region: us-east-1
    vpc_id: vpc-0141944e897367945
    serviceType: privatelink-consumer
    serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
    thirdpartyName: Datadog
    thirdPartyID: 123456
    rules:
    - request_id: RQ-001
        business_justification: >
            Create access from acct-1 intranet nat gateway to datadog api vpc-endpoint. 
        source:
        account_id: 111122223333
        vpc_id: vpc-aaa
        region: us-east-1
        ips:
            - 10.11.1.1/32
            - 10.12.1.1/32
            - 10.13.1.1/32
        protocol: tcp
        port: 443
        appid: ssl
        url: https://api.datadoghq.com
        enable_palo_inspection: true
    - request_id: RQ-001
        business_justification: >
            Create access from acct-1 intranet nat gateway to datadog api vpc-endpoint. 
        source:
        account_id: 111122223333
        vpc_id: vpc-aaa
        region: us-east-1
        ips:
            - 10.11.1.1/32
            - 10.12.1.1/32
            - 10.13.1.1/32
        protocol: tcp
        port: 69
        appid: ssl
        url: https://api.datadoghq.com
        enable_palo_inspection: true
    ```
1. ```consumer_rule_combinations```
- Flatten each rule per CIDR, including metadata and tags. 
```
consumer_rule_combinations = [
  {
    key        = "Datadog-us-east-1-tcp-443-10.11.1.1/32-0-0"
    dedup_key  = "Datadog-us-east-1-tcp-443-10.11.1.1/32"
    sg_key     = "Datadog-us-east-1"
    region     = "us-east-1"
    protocol   = "tcp"
    port       = 443
    cidr       = "10.11.1.1/32"
    sg_name    = "datadog-vpce-svc-064ea718f8d0ead77-us-east-1-sg"
    rule_tags = {
      RequestID          = "RQ-001"
      SourceAccountID    = "111122223333"
      SourceVPC          = "vpc-aaa"
      SourceRegion       = "us-east-1"
      EnablePaloInspection = "true"
      AppID              = "ssl"
      URL                = "https://api.datadoghq.com"
    }
  },
  {
    key        = "Datadog-us-east-1-tcp-69-10.13.1.1/32-1-2"
    dedup_key  = "Datadog-us-east-1-tcp-69-10.13.1.1/32"
    ...
  },
  # Total: 6 entries (2 rules × 3 CIDRs)
]
```

2. ```consumer_palo_rule_combinations```
- Flatten rules for Palo Alto grouping, keyed by appid, port & URL. 
```
consumer_palo_rule_combinations = [
  {
    palo_key  = "Datadog-us-east-1-tcp-443-ssl-api.datadoghq.com"
    sg_key    = "Datadog-us-east-1"
    region    = "us-east-1"
    protocol  = "tcp"
    port      = 443
    appid     = "ssl"
    url       = "https://api.datadoghq.com"
    source_ips = ["10.11.1.1/32"]
  },
  {
    palo_key  = "Datadog-us-east-1-tcp-69-ssl-api.datadoghq.com"
    source_ips = ["10.12.1.1/32"]
  },
  # Total: 6 entries (2 rules × 3 CIDRs)
]
```

3. ```consumer_palo_grouped_rules```
- Group Palo Alto rules by ```region``` and ```sg_key```, deduplicated by ```palo_key```. 
```
consumer_palo_grouped_rules = {
  "us-east-1" = {
    "Datadog-us-east-1" = {
      "Datadog-us-east-1-tcp-443-ssl-api.datadoghq.com" = {
        protocol   = "tcp"
        port       = 443
        appid      = "ssl"
        url        = "https://api.datadoghq.com"
        source_ips = [
          "10.11.1.1/32",
          "10.12.1.1/32",
          "10.13.1.1/32"
        ]
      },
      "Datadog-us-east-1-tcp-69-ssl-api.datadoghq.com" = {
        port = 69
        source_ips = [
          "10.11.1.1/32",
          "10.12.1.1/32",
          "10.13.1.1/32"
        ]
      }
    }
  }
}
```

4. ```consumer_aws_rules_deduped```
- De-duplicate rules by ```protocol+port+CIDR```
```
consumer_aws_rules_deduped = {
  "Datadog-us-east-1-tcp-443-10.11.1.1/32" = {
    protocol = "tcp"
    port     = 443
    cidr     = "10.11.1.1/32"
    ...
  },
  ...
  "Datadog-us-east-1-tcp-69-10.13.1.1/32" = {
    protocol = "tcp"
    port     = 69
    cidr     = "10.13.1.1/32"
  }
  # Total: 6 unique entries
}
```

5. ```consumer_sgs_by_region```
- Final structure passed to the main.tf module using ```for_each```.
```
consumer_sgs_by_region = {
  "us-east-1" = {
    "Datadog-us-east-1" = {
      region                = "us-east-1"
      sg_name               = "datadog-vpce-svc-064ea718f8d0ead77-us-east-1-sg"
      vpc_id                = "vpc-0141944e897367945"
      aws_rules             = { ...6 rules... }
      palo_rules            = {
        "Datadog-us-east-1-tcp-443-ssl-api.datadoghq.com" = {
          port = 443
          ...
        },
        "Datadog-us-east-1-tcp-69-ssl-api.datadoghq.com" = {
          port = 69
          ...
        }
      }
      palo_protocols_ports  = ["tcp-443", "tcp-69"]
      palo_source_ips       = [
        "10.11.1.1/32",
        "10.12.1.1/32",
        "10.13.1.1/32"
      ]
    }
  }
}
```