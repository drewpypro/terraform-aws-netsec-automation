# Duplicates in same list request example#1
- ./tests/requests/bad-duplicates-within-example1-policy.yaml

## Submitted request

```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: dupes-within-policy1
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.11.1.1/32
        - 10.12.1.1/32
        - 10.11.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
```

## Output

🏛️ Duplicates detected in submitted policy

```yaml
		- request_id: RQ-001
		  source:
			ips:
	>>    - 10.11.1.1/32
			  - 10.12.1.1/32
	>>    - 10.11.1.1/32
		  protocol: tcp
		  port: 69
		  appid: ssl
		  url: https://api.datadoghq.com	  
```

# Duplicates in separate rules within request example#2
- ./tests/requests/bad-duplicates-within-example2-policy.yaml

## Submitted request
- policies/dupes-within-policy2-vpce-svc-064ea718f8d0ead77-us-west-2-policy.yaml
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: dupes-within-policy2
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
  - request_id: RQ-002
    source:
      ips:
        - 10.11.1.1/32
        - 10.13.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
	
```

## Output

🏛️ Duplicates detected in submitted policy

	```yaml
	  rules:
		- request_id: RQ-001
		  source:
			ips:
			  - 10.12.1.1/32
	>>    - 10.13.1.1/32
		  protocol: tcp
		  port: 69
		  appid: ssl
		  url: https://api.datadoghq.com
		- request_id: RQ-002
		  source:
			ips:
			  - 10.11.1.1/32
	>>    - 10.13.1.1/32
		  protocol: tcp
		  port: 69
		  appid: ssl
		  url: https://api.datadoghq.com
	```


# Duplicate 5-tuple between rules within request example#3
- ./tests/requests/bad-duplicates-within-example3-policy.yaml

## Submitted request

```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: dupes-within-policy3
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
  - request_id: RQ-002
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

🏛️ Duplicates detected in submitted policy

```yaml
	  rules:
		- request_id: RQ-001
		  source:
			ips:
	>>    - 10.12.1.1/32
	>>    - 10.13.1.1/32
	>>  protocol: tcp
	>>  port: 69
	>>  appid: ssl
	>>  url: https://api.datadoghq.com
		- request_id: RQ-002
		  source:
			ips:
	>>    - 10.12.1.1/32
	>>    - 10.13.1.1/32
	>>  protocol: tcp
	>>  port: 69
	>>  appid: ssl
	>>  url: https://api.datadoghq.com
```

# Duplicate 5-tuple between rules within request example#4
- ./tests/requests/bad-duplicates-within-example4-policy.yaml

## Submitted request
```yaml
security_group:
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: dupes-within-policy4
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
  - request_id: RQ-002
    source:
      ips:
        - 10.12.1.1/32
        - 10.15.1.1/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.datadoghq.com
	
```


## Output

🏛️ Duplicates detected in submitted policy

```yaml
	  rules:
		- request_id: RQ-001
		  source:
			ips:
	>>    - 10.12.1.1/32
			  - 10.13.1.1/32
		  protocol: tcp
		  port: 69
		  appid: ssl
		  url: https://api.datadoghq.com
		- request_id: RQ-002
		  source:
			ips:
	>>    - 10.12.1.1/32
			  - 10.15.1.1/32
		  protocol: tcp
		  port: 69
		  appid: ssl
		  url: https://api.datadoghq.com
```

# Duplicate 5-tuple between rules within request example#5
- ./tests/requests/bad-duplicates-within-example5-policy.yaml

## Submitted request
```yaml
rules:
  - request_id: RQ-001
    source:
      ips:
        - 10.1.1.1/32
        - 10.1.1.2/32
        - 10.1.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.example.com
  - request_id: RQ-002
    source:
      ips:
        - 10.1.1.1/32
        - 10.1.1.2/32
        - 10.1.1.1/32
    protocol: tcp
    port: 443
    appid: ssl
    url: https://api.example.com
```

## Output

🏛️ Duplicates detected in submitted policy

```yaml
rules:
  - request_id: RQ-001
    source:
      ips:
  >>    - 10.1.1.1/32
  >>    - 10.1.1.2/32
  >>    - 10.1.1.1/32
  >>  protocol: tcp
  >>  port: 443
  >>  appid: ssl
  >>  url: https://api.example.com
  - request_id: RQ-002
    source:
      ips:
  >>    - 10.1.1.1/32
  >>    - 10.1.1.2/32
  >>    - 10.1.1.1/32
  >>  protocol: tcp
  >>  port: 443
  >>  appid: ssl
  >>  url: https://api.example.com
```

