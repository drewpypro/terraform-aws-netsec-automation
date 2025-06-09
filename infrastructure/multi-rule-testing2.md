## Test Input
```yaml
security_group:
  ...
  serviceType: privatelink-consumer
  thirdpartyName: Datadog
  ...
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.50.0.0/24
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-002
    source:
      ips:
        - 10.58.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-004454
    source:
      ips:
        - 10.50.0.0/24
    protocol: tcp
    port: 27017
    appid: 
    url: 
  - request_id: RQ-002
    source:
      ips:
        - 10.58.1.1/32
    protocol: tcp
    port: 27017
    appid: 
    url:  
  - request_id: RQ-004454
    source:
      ips:
        - 10.50.0.0/24
    protocol: tcp
    port: 443
    appid: ssl
    url: 
  - request_id: RQ-002
    source:
      ips:
        - 10.58.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url:  
```

## Expected Output (summarized)

- AWS SG (cannot support dupes, list is accepted but still writes rules as cidr, proto, port)
    # source_cidr, proto/port
    1. 10.50.0.0/24, tcp/443
    2. 10.58.1.1/32, tcp/443
    3. 10.50.0.0/24, tcp/27017
    4. 10.58.1.1/32, tcp/27017
- Palo rules (separate by proto/port, appid (if null, then any) and url-category-object (if null, then any)
    #source_cidr, proto/port, appid, url
    1. {10.50.0.0/24, 10.58.1.1/32}, tcp/443, ssl, api.datadoghq.com
    2. {10.50.0.0/24, 10.58.1.1/32}, tcp/27017, any, any
    3 {10.50.0.0/24, 10.58.1.1/32}, tcp/443, ssl, any

