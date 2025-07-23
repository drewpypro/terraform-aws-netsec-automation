| Path                                      | Type     | Description                                                                 |
|-------------------------------------------|----------|-----------------------------------------------------------------------------|
| `security_group`                          | object   | Top-level block defining the security group and metadata                    |
| `security_group.request_id`               | string   | Unique identifier for the security group request                            |
| `security_group.business_justification`   | string   | Reason for creating the security group                                      |
| `security_group.accountId`                | string   | AWS account ID where the security group will be created                     |
| `security_group.region`                   | string   | AWS region for the security group                                           |
| `security_group.vpc_id`                   | string   | VPC ID where the security group will be attached                            |
| `security_group.serviceType`              | string   | Type of service being accessed (e.g., privatelink-consumer)                 |
| `security_group.serviceName`              | string   | Fully qualified AWS service name used in the PrivateLink connection         |
| `security_group.thirdpartyName`           | string   | Name of the third-party service provider                                    |
| `security_group.thirdPartyID`             | string   | Internal identifier for the third-party service                             |
| `rules`                                   | array    | List of access rules associated with the security group                     |
| `rules[].request_id`                      | string   | Identifier for the rule request, should match the parent security group     |
| `rules[].business_justification`          | string   | Explanation for why the specific rule is needed                             |
| `rules[].source`                          | object   | Information about the source of traffic                                     |
| `rules[].source.account_id`               | string   | AWS account ID from which the traffic originates                            |
| `rules[].source.vpc_id`                   | string   | VPC ID of the source network                                                |
| `rules[].source.region`                   | string   | AWS region of the source                                                    |
| `rules[].source.ips`                      | array    | List of CIDR blocks for source IPs                                          |
| `rules[].protocol`                        | string   | Protocol used for traffic (e.g., tcp, udp)                                  |
| `rules[].port`                            | integer  | Destination port allowed for the rule                                       |
| `rules[].appid`                           | string   | Application identifier for logging or inspection purposes                   |
| `rules[].url`                             | string   | Target URL or endpoint used in the rule                                     |
| `rules[].enable_palo_inspection`          | boolean  | Whether to enable Palo Alto inspection for this rule                        |
