# Good request example#1
- ./tests/requests/good-request-example1-policy.yaml

## Submitted request
- policies/good-policy1-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: good-policy1
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
```

## Output

💦 No Duplicates detected!


# Good request example#2
- ./tests/requests/good-request-example2-policy.yaml

## Submitted request
- policies/good-policy2-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: good-policy2
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.datadoghq.com
	
```

## Output

💦 No Duplicates detected!



# Good request example#3
- ./tests/requests/good-request-example3-policy.yaml

## Submitted request
- policies/good-policy3-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: good-policy3
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: mongodb
    url: https://api.datadoghq.com
	
```

## Output

💦 No Duplicates detected!


# Good request example#4
- ./tests/requests/good-request-example4-policy.yaml

## Submitted request
- policies/good-policy4-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: good-policy4
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: udp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
	
```

## Output

💦 No Duplicates detected!


# Good request example#5
- ./tests/requests/good-request-example5-policy.yaml

## Submitted request
- policies/good-policy5-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: good-policy5
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
  - request_id: RQ-001
    source:
      ips:
        - 10.12.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq2.com
	
```

## Output

💦 No Duplicates detected!
