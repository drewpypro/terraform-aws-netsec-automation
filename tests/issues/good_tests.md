```yaml
security_group:
    request_id: RQ-001
    business_justification: Creating security-group and palo alto rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
    accountId: 6666666
    region: us-east-1
    vpc_id: vpc-05ebefacb081c3018
    serviceType: privatelink-consumer
    serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea3r2f8d0ead77
    thirdpartyName: workday
    thirdPartyID: TP-0010
rules:
  - request_id: RQ-001
    business_justification: Creating rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
    source:
      account_id: 111122223333
      vpc_id: vpc-aaa
      region: us-east-1
      ips:
        - 10.11.1.2/32
        - 10.12.1.2/32
        - 10.13.1.2/32
    protocol: tcp
    port: 69
    appid: ssl
    url: https://api.workday.com
  - request_id: RQ-002
    business_justification: Creating rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
    source:
      account_id: 111122223333
      vpc_id: vpc-aaa
      region: us-east-1
      ips:
        - 10.11.1.2/32
        - 10.12.1.2/32
        - 10.13.1.2/32
    protocol: tcp
    port: 77
    appid: ssl
    url: https://api.workday.com
```

```yaml
security_group:
  request_id: RQ-001
  business_justification: Creating security-group and palo alto rules for thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
  accountId: 6666666
  region: us-east-1
  vpc_id: vpc-05ebefacb081c3018
  serviceType: privatelink-consumer
  serviceName: com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77
  thirdpartyName: miro
  thirdPartyID: TP-0013
rules:
  - request_id: RQ-001
    business_justification: Creating rules to allow internal hosts to connect to thirdparty splunk to enable splunk saas logging required for enterprise visibility operations. 
  source:
    account_id: 6666666
    vpc_id: vpc-05ebefacb081c3018
    region: us-east-1
    ips:
      - 10.11.1.1/32
      - 10.12.1.1/32
  protocol: tcp
  port: 6969
  appid: ssl
  url: https://api.miro.com
  enable_palo_inspection: true
```