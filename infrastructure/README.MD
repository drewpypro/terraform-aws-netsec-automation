# terraform infrastructure
![netsec-automation-highlevel](../img/aws-netsec-automation-test-highlevel.png)

```yaml
request_id: req-20240428-xyz
submitted_by: <derived automatically>
submitted_at: <derived automatically>

overall_business_justification: >
  Overall business justification for all requests below (required)

requests:
  - business_justification: >
      Per request business justification (required)
    source:
      account_id: (optional)
      vpc_id: (optional)
      region: (optional)
      security_group_ids: <must be specific id, optional when ips are called>
      ips: [list of IP's, optional when security_group_ids are called]
    destination:
      account_id: (optional)
      vpc_id: (optional)
      region: (optional)
      security_group_ids: <must be specific id, optional when ips are called>
      ips: [list of IP's, optional when security_group_ids are called]
    proto: <tcp|udp|icmp|any> (required, only one)
    port: <1-65535> (required, can be range or single port )
    appid: ssl (optional)
    url:  (optional)
```

# Logic
- if sg-id is supplied write rules to that sg-id 
- if sg-id is supplied for source, but only ip supplied for dest, create an egress cidr_ipv4 rule
- if sg-id is supplied for destination, but only IP supplied for src, create an ingress cidr_ipv4 rule
- if sg-id is supplied for source and destination, create an ingress and egress rule on each respective sg-id
- if enable_palo_inspection is true; generate palo alto policy using IPs only. 

