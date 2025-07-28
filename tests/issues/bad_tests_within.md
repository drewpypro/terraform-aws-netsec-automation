```yaml
security_group:
    request_id: RQ-001
    business_justification: Creating security-group and palo alto rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
    accountId: 6666666
    region: us-east-1
    vpc_id: vpc-05ebefacb081c3018
    serviceType: privatelink-consumer
    serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea3r2f8d0ead77
    thirdpartyName: snowflake
    thirdPartyID: TP-0008
    rules:
      - request_id: RQ-001
        source:
          ips:
            - 10.11.1.2/32
            - 10.12.1.2/32
            - 10.11.1.2/32
        protocol: tcp
        port: 443
        appid: ssl
        url: https://api.snowflake.com
```

```yaml
security_group:
    request_id: RQ-001
    business_justification: Creating security-group and palo alto rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
    accountId: 6666666
    region: us-east-1
    vpc_id: vpc-05ebefacb081c3018
    serviceType: privatelink-consumer
    serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea3r2f8d0ead77
    thirdpartyName: snowflake
    thirdPartyID: TP-0008
    rules:
      - request_id: RQ-001
        source:
          ips:
            - 10.11.1.2/32
            - 10.12.1.2/32
            - 10.13.1.2/32
        protocol: tcp
        port: 443
        appid: ssl
        url: https://api.snowflake.com
      - request_id: RQ-002
        source:
          ips:
            - 10.11.1.2/32
            - 10.12.1.2/32
            - 10.13.1.2/32
        protocol: tcp
        port: 443
        appid: ssl
        url: https://api.snowflake.com
```

```yaml
security_group:
    request_id: RQ-001
    business_justification: Creating security-group and palo alto rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
    accountId: 6666666
    region: us-east-1
    vpc_id: vpc-05ebefacb081c3018
    serviceType: privatelink-consumer
    serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea3r2f8d0ead77
    thirdpartyName: snowflake
    thirdPartyID: TP-0008
    rules:
      - request_id: RQ-001
        source:
          ips:
            - 10.12.1.1/32
            - 10.13.1.1/32
        protocol: tcp
        port: 69
        appid: ssl
        url: https://api.snowflake.com
      - request_id: RQ-002
        source:
          ips:
            - 10.12.1.1/32
            - 10.15.1.1/32
        protocol: tcp
        port: 69
        appid: ssl
        url: https://api.snowflake.com
```


```yaml
security_group:
    request_id: RQ-001
    business_justification: Creating security-group and palo alto rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
    accountId: 6666666
    region: us-east-1
    vpc_id: vpc-05ebefacb081c3018
    serviceType: privatelink-consumer
    serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea3r2f8d0ead77
    thirdpartyName: snowflake
    thirdPartyID: TP-0008
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
        url: https://api.snowflake.com
      - request_id: RQ-002
        source:
          ips:
            - 10.1.1.1/32
            - 10.1.1.2/32
            - 10.1.1.1/32
        protocol: tcp
        port: 443
        appid: ssl
        url: https://api.snowflake.com
```

