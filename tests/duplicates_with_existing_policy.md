# Existing Policy
- ./tests/policies/existing-policy.yaml

```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: existing-policy
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.11.1.1/32
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-002
    source:
      ips:
        - 10.11.1.2/32
        - 10.12.1.2/32
        - 10.13.1.2/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-003
    source:
      ips:
        - 10.1.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
```

# Duplicates with existing policy example#1
- ./tests/requests/bad-duplicates-with-existing-example1-policy.yaml

## Submitted request
- policies/existing-policy1-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: existing-policy
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.11.1.2/32
        - 10.12.1.2/32
        - 10.13.1.2/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
```

## Output

🏛️ Duplicates detected in existing policy {$policy_file}

# Submitted policy rule index #1
```yaml
    - request_id: RQ-001
      source:
        ips:
>>        - 10.11.1.2/32
>>        - 10.12.1.2/32
>>        - 10.13.1.2/32
>>    protocol: tcp
>>    port: 69
>>    appid: ssl
>>    url: https://api.datadoghq.com
```

## Existing policy rule index #2
```yaml
    - request_id: RQ-002
      source:
        ips:
>>        - 10.11.1.2/32
>>        - 10.12.1.2/32
>>        - 10.13.1.2/32
>>    protocol: tcp
>>    port: 69
>>    appid: ssl
>>    url: https://api.datadoghq.com
```

# Duplicates with existing policy example#2
- ./tests/requests/bad-duplicates-with-existing-example2-policy.yaml

## Submitted request
- policies/existing-policy1-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: existing-policy
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.11.1.1/32
        - 10.33.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
```

## Output

🏛️ Duplicates detected in existing policy {$policy_file}

# Submitted policy rule index #1
```yaml
    - request_id: RQ-001
      source:
        ips:
>>        - 10.11.1.1/32
          - 10.33.1.1/32
      protocol: tcp
      port: 69
      appid: ssl
      url: https://api.datadoghq.com
```

## Existing policy rule index #1
```yaml
    - request_id: RQ-002
      source:
        ips:
>>        - 10.11.1.1/32
          - 10.12.1.1/32
          - 10.13.1.1/32
      protocol: tcp
      port: 69
      appid: ssl
      url: https://api.datadoghq.com
```


# Duplicates with existing policy example#3
- ./tests/requests/bad-duplicates-with-existing-example3-policy.yaml

## Submitted request
- policies/existing-policy1-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: existing-policy
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.11.1.2/32
        - 10.12.1.2/32
        - 10.13.1.2/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-002
    source:
      ips:
        - 10.11.1.1/32
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
```

## Output

🏛️ Duplicates detected in existing policy {$policy_file}

# Submitted policy rule index #1 matches existing policy rule index #2
```yaml
    - request_id: RQ-001
      source:
        ips:
>>        - 10.11.1.2/32
>>        - 10.12.1.2/32
>>        - 10.13.1.2/32
>>    protocol: tcp
>>    port: 69
>>    appid: ssl
>>    url: https://api.datadoghq.com
```


## Submitted policy rule index #2 matches existing policy rule index #1
```yaml
    - request_id: RQ-001
      source:
        ips:
>>        - 10.11.1.1/32
>>        - 10.12.1.1/32
>>        - 10.13.1.1/32
>>    protocol: tcp
>>    port: 69
>>    appid: ssl
>>    url: https://api.datadoghq.com
```

## Existing policy rule index #1
```yaml
    - request_id: RQ-002
      source:
        ips:
>>        - 10.11.1.1/32
>>        - 10.12.1.1/32
>>        - 10.13.1.1/32
>>    protocol: tcp
>>    port: 69
>>    appid: ssl
>>    url: https://api.datadoghq.com
```

## Existing policy rule index #2
```yaml
    - request_id: RQ-002
      source:
        ips:
>>        - 10.11.1.2/32
>>        - 10.12.1.2/32
>>        - 10.13.1.2/32
>>    protocol: tcp
>>    port: 69
>>    appid: ssl
>>    url: https://api.datadoghq.com
```




# Duplicates with existing policy example#4

## Submitted request
- ./tests/requests/bad-duplicates-with-existing-example4-policy.yaml

```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: existing-policy
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.11.1.1/32
        - 10.33.1.1/32
		    - 10.13.1.2/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
```

## Output

🏛️ Duplicates detected in existing policy {$policy_file}

# Submitted policy rule index #1
```yaml
    - request_id: RQ-001
      source:
        ips:
>>        - 10.11.1.1/32
          - 10.33.1.1/32
>>        - 10.13.1.2/32
      protocol: tcp
      port: 69
      appid: ssl
      url: https://api.datadoghq.com
```

## Duplicate in existing policy rule index #1
```yaml
    - request_id: RQ-002
      source:
        ips:
>>        - 10.11.1.1/32
          - 10.12.1.1/32
          - 10.13.1.1/32
      protocol: tcp
      port: 69
      appid: ssl
      url: https://api.datadoghq.com
```

## Duplicate in existing policy rule index #2
```yaml
    - request_id: RQ-002
      source:
        ips:
          - 10.11.1.2/32
          - 10.12.1.2/32
>>        - 10.13.1.2/32
      protocol: tcp
      port: 69
      appid: ssl
      url: https://api.datadoghq.com
```


# Duplicates with existing policy example#5
- ./tests/requests/bad-duplicates-with-existing-example5-policy.yaml

## Submitted request

```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-xxx
  thirdpartyName: existing-policy
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.1.1.1/32
        - 10.1.1.2/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-002
    source:
      ips:
        - 10.1.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
```

## Output

🏛️ Duplicates detected in submitted policy

```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-xxx
  thirdpartyName: existing-policy
rules:
  - request_id: RQ-001
    source:
      ips:
>>      - 10.1.1.1/32
        - 10.1.1.2/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-002
    source:
      ips:
>>      - 10.1.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
```

🏛️ Duplicates detected in existing policy {$policy_file}

# Submitted policy rule index #1 matches existing policy index #3
```yaml
  - request_id: RQ-001
    source:
      ips:
>>      - 10.1.1.1/32
        - 10.1.1.2/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
```

# Submitted policy rule index #2 matches existing policy index #3

```yaml
  - request_id: RQ-002
    source:
      ips:
>>      - 10.1.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
```

# Duplicate in existing policy rule index #3
```yaml
  - request_id: RQ-003
    source:
      ips:
>>      - 10.1.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
```


