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

# Structure
```
thirdparty-access-nonprod-repo/
├── policies/
│   ├── us-west-2.yaml
│   └── us-east-1.yaml

thirdparty-access-prod-repo/
├── policies/
│   ├── us-west-2.yaml
│   └── us-east-1.yaml
```

## 🛡️ drewpy.pro License

Copyright (c) 2025 drewpy.pro

This software is provided freely for personal, academic, or internal enterprise use.

> **Commercial use, redistribution, or integration into hosted or monetized services requires prior written permission.**

All derived works or deployments must visibly attribute the original author:

    drewpy.pro

Please retain a link to this license file in all copies or modifications.

If you find this project useful and wish to use it in a commercial product, hosted service, or enterprise platform, please get in touch:

📧 licensing@drewpy.mozmail.com

> 💡 Note: This project was developed during drewpy.pro hours using drewpy.pro equipment and services.  
> It is not affiliated with any employer or built using any company-owned resources.


---

## Summary

- ✅ Personal/internal use — allowed
- ✅ Learning and adaptation — encouraged
- 🧾 Commercial or hosted use — by permission
- 🚫 Obscuring authorship — not permitted