# Terraform & AWS => ♥ UiPath Orchestrator.
Steps to provision Orchestrator on AWS in ASG (Auto scaling group):
1. Install terraform  v0.12.3 (https://learn.hashicorp.com/terraform/getting-started/install.html).
2. Complete the variables.tf file (see inputs below). For Orchestrator hardware requirements and EC2 types check : https://aws.amazon.com/ec2/instance-types/  and https://orchestrator.uipath.com/docs/hardware-requirements-orchestrator.
3. Change directory to path of the Orchestrator plan (cd C:\path\to\orchestrator\plan).
4. Run : ` terraform init `
5. Run : ` terraform plan `
6. Check the plan of the resources to be deployed and type ` yes ` if you agree with the plan.
7. Wait 15-20 mins and enjoy! The password of the Orchestrator is the password used to ` orchestrator_password ` variable.

## Terraform version
Terraform v0.12.3

## Inputs

| Name | Description | Type | Default | Required |
|---|--------------|:----:|:-----:|:-----:|
| aws\_region | The region for UiPath Orchestrator deployment. | string | `"eu-west-2"` | yes |
| access\_key | AWS Access Key. | string | `"SAGFGDGVGDBXCVER"` | yes |
| secret\_key | AWS Secret Access Key. | string | `"+SAGFGDGDGVGDBXCVER=="` | yes |
| key\_name | Name of the SSH keypair to use in AWS. | map | `aws_ssh_key` | yes |
| aws\_app\_instance\_type | Orchestrator Instance type. | string | `"m4.large"` | yes |
| admin\_password | Windows Administrator password used to login in the provisioned VMs. | string | `"WinP@55!"` | yes |
| orchestrator\_password | Orchestrator administrator password to login in Default and Host Tenant. | string | `"0rCh35Tr@tor!"` | yes |
| orchestrator\_passphrase | Orchestrator Passphrase in order to generate NuGet API keys, App encryption key and machine keys. | string | `"2Custom5P@ssPh@se"` | yes |
| orchestrator\_license | Orchestrator license code. The license created with regutil. | string | `"TheLicenseCreate dwithRegUtil"` | yes |
| orchestrator\_versions | Orchestrator Version. | string | `"19.10.15"` | yes |
| haa-user | High Availability Add-on username. Type email. | string | `"test@corp.com"` | yes |
| haa-password | High Availability Add-on username password. | string | `"123456"` | yes |
| haa-license | High Availability Add-on license key. | string | `"353tgewsdfweg34t342rftg23g2g23t2r32r2353tgewsdfweg34t34"` | yes |
| newSQL | Provision new RDS DB. Change default value from no to yes if you want to create a new RDS DB. | string | `"no"` | yes |
| db\_username | RDS master user name or username of the existing database. | string | `"devawsdb"` | yes |
| db\_password | Existing Database username password or create a password for the RDS.| string | `"!vfdgva%gsd"` | yes |
| db\_name | RDS database name or the name of an existing database. | string | `"awstest"` | yes |
| sql\_srv | SQL Server FQDN if you have an existing SQL server. | string | `"amazontest.net"` | yes |
| rds\_allocated\_storage | Allocated storage (in GB) for the RDS instance. | string | `"100"` | yes |
| rds\_instance\_class | Instance size type of the RDS instance. | string | `"db.m4.large"` | yes |
| rds\_multi\_az | True if the RDS instance is multi-AZ. | string | `"false"` | yes |
| skip\_final\_snapshot | Determines whether a final DB snapshot is created before the DB instance is deleted. | string | `"true"` | yes |
| aws\_availability\_zones | Availability zones for each region. | map |   | yes |
| environment | Environment name, used as prefix to tag Name of the resources. | string | `"dev"` | yes |
| application | Application stack name, used as prefix to tag Name of the resources. | string | `"UiPath_Stack"` | yes |
| role | Role name for S3 Bucket. | string | `"s3"` | yes |
| s3BucketName | New S3 Bucket Name. | string | `"tfs3orc"` | yes |
| instance\_count | The desired count of the Orchestrator instances in the ASG. | string | `"1"` | yes |
| domain | The domain to use to host the project. This should exist as a hosted zone in Route 53. | string | `"existingdomain.com"` | yes |
| subdomain | New subdomain used for ALB. | string | `"alb-orch"` | yes |
| certificate\_arn | Certificate ARN of an existing certificate (wildcard certificate). | string | `""` | yes |
| associate\_public\_ip\_address | Associate public IP to EC2 Orchestrator instances. | string | `"false"` | yes |
| cidr\_block | VPC cidr block. | string | `"10.0.0.0/16"` | yes |
| security\_cidr\_block | Security Group cidr block. Only 80 and 443 must have access to the internet if you want to access the Orchestrator via the Internet. | string | `"0.0.0.0/0"` | yes |

## Outputs

| Name | Description |
|------|-------------|
| bastion\_public\_ip | Public IP of the Bastion Host (Jumbox host). |
| lb\_dns\_name | Load balancer FQDN. |
| haa\_master\_ip | Private IP of the HAA master node. |
| haa\_slave\_ip |  Private IP of the HAA slave nodes.|
