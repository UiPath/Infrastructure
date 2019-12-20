# Terraform & AWS => ♥ UiPath Robot.
Steps to provision UiPath Robot in AWS :
1. Install terraform  v0.12.3 (https://learn.hashicorp.com/terraform/getting-started/install.html).
2. Complete the variables.tf file (see inputs below). For Robots hardware requirements and EC2 types check : https://aws.amazon.com/ec2/instance-types/  and https://robot.uipath.com/docs/hardware-requirements.
3. Change directory to path of the UiPath Robot plan (cd C:\path\to\uirobot\plan).
4. Run : ` terraform init `
5. Run : ` terraform plan `
6. Check the plan of the resources to be deployed and type ` yes ` if you agree with the plan.
7. Wait 5-10 mins per EC2 instance and enjoy!

## Terraform version
Terraform v0.12.3

## Inputs

| Name | Description | Type | Default | Required |
|:----:|-----|:----:|:----:|:--:|
| aws\_region | AWS region for deployment. | string | `"eu-west-2"` | yes |
| access\_key | AWS access key. | string | `"SGFASDCXVXCBAD"` | yes |
| secret\_key | AWS secret key. | string | `"+SGFASDCXVXCBAD+SGF"` | yes |
| key\_name | SSH keypair to be used. | map | `SSH_KEY` | yes |
| aws\_app\_instance\_type | Robot EC2 Instance type. | string | `"t2.medium"` | yes |
| disk\_size | Local disk size. | string | `"100"` | yes |
| instance\_count | Number of the Robots to be created. | string | `"2"` | yes |
| application | Robots and stack prefix name. | string | `"uirobot"` | yes |
| environment | Environment type, also used as a prefix for the stack. | string | `"prod"` | yes |
| set\_local\_adminpass | Set local admin password. | string | `"yes"` | yes |
| admin\_password | Local windows administrator password. If variable 'set_local_adminpass' is 'yes'. | string | `"Local@dminP@55!*"` | yes |
| cidr\_block | VPC cidr block. | string | `"10.0.0.0/16"` | yes |
| associate\_public\_ip\_address | Associate public IP to Robots EC2 instances. | string | `"false"` | yes |
| security\_cidr\_block | Security Group cidr block. | string | `"0.0.0.0/0"` | yes |
| aws\_availability\_zones | Availability zones for each region. Example to get the second AZ in Singapore. | map | `${element(var.aws_availability_zones ['ap-southeast-1'], 0)}` | yes |
| orchestrator\_url | URL of an existing and licensed Orchestrator. | string | `"https://my-licensed-orchestrator.net"` | yes |
| tennant | Orchestrator Tennant. | string | `"default"` | yes |
| robot\_type | Robot type : Attended, Unattended, Development or Nonproduction. | string | `"Unattended"` | yes |
| api\_user | API user with View, Edit, Create, Delete roles for Machines,Robots and Environments. | string | `"apiUser"` | yes |
| api\_user\_password | API user password. | string | `"ApiP@ssWd"` | yes |
| robot\_local\_account | Robot local account which will be created. Don't use 'administrator'. | string | `"robolocal"` | yes |
| robot\_local\_account\_password | Robot local account password. | string | `"R@pVPsf@Fx"` | yes |
| robot\_local\_account\_role | Robot local accout role : localadmin or localuser | string | `"localadmin"` | yes |

## Outputs

| Name | Description |
|------|-------------|
| bastion\_public\_ip | BastionHost public IP. |