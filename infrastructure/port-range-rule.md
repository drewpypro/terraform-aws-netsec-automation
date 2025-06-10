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
    port: 9000-10000
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-002
    source:
      ips:
        - 10.58.1.1/32
    protocol: tcp
    port: 8010-8020
    appid: ssl
    url: https://api.datadoghq.com
```

## Expected Output (summarized)

- AWS SG (cannot support dupes, list is accepted but still writes rules as cidr, proto, port)
    # source_cidr, proto/port
    1. 10.50.0.0/24, tcp/9000-10000 (from_port, to_port)
    2. 10.58.1.1/32, tcp/8010-8020 (from_port, to_port)
- Palo rules (separate by proto/port, appid (if null, then any) and url-category-object (if null, then any)
    #source_cidr, proto/port, appid, url
    1. 10.50.0.0/24, tcp/9000-10000, ssl, api.datadoghq.com
	2. 10.58.1.1/32, tcp/8010-8020, ssl, api.datadoghq.com
