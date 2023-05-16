# UiRobot-GCP-Terraform
 UiPath Robot GCP deployment via Terraform.

 [![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/UiPath/Infrastructure) </br> </br>
 !! If you deploy the solution from the above button, then delete ``` credentials = "${file("terraform-245706-bba73b77aff6.json")}" ``` from ```main.tf``` and complete ```variables.tf```. !!

 ## First steps:
1. Install terraform v0.12.3 (check Installing Terraform).
2. Complete the variables.tf file (see Inputs below). Complete the variables.tf file (see Inputs below). For Robots hardware requirements and GCP VM types check : https://robot.uipath.com/docs/hardware-requirements and https://cloud.google.com/compute/docs/machine-types.
3. Change directory to path of the Orchestrator plan (cd C:\path\to\orchestrator\plan).
4. Run : ` terraform init `
5. Run : ` terraform plan `
6. Check the plan of the resources to be deployed and type ` yes ` if you agree with the plan.
7. Wait 5-10 mins per GCP instance and enjoy!


## Installing Terraform
Please check : https://learn.hashicorp.com/terraform/getting-started/install.html

## Terraform version
Terraform v0.12.3


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| region | Region | string | `"us-west1"` | yes |
| az | Availability Zone | string | `"us-west1-a"` | yes |
| image | GCP instances image | string | `"windows-server-2016-dc-v20190620"` | yes |
| vm\_type | Machine type : CPU and RAM size. See https://cloud.google.com/compute/docs/machine-types | string | `"n1-standard-4"` | yes |
| instance\_count | Number of robots to be created. | string | `"2"` | yes |
| disk\_size | Disk size for each VM. | string | `"50"` | yes |
| app\_name | Base VM name. | string | `"uirobot"` | yes |
| set\_local\_adminpass | Set local admin password. | string | `"yes"` | yes |
| admin\_password | Local windows administrator password. If variable 'set_local_adminpass' is 'yes'. | string | `"Local@dminP@55!*"` | yes |
| robot\_local\_account\_role | Robot local account role : localadmin or localuser | string | `"localadmin"` | yes |
| orchestrator\_url | orchestrator url | string | `"https://corp-orchestrator.com"` | yes |
| orchestrator\_tennant | orchestrator tennant | string | `"default"` | yes |
| orchestrator\_admin | orchestrator admin username | string | `"admin"` | yes |
| orchestrator\_adminpw | orchestrator admin password | string | `"Orc@dminP@55!*"` | yes |
| vm\_username | Robot VM username | string | `"uirobot"` | yes |
| vm\_password | Robot VM password | string | `"UiRobot@dminP@55!"` | yes |
| robot\_type | Robot type | string | `"Unattended"` | yes |

## Outputs

| Name | Description |
|------|-------------|
| public\_ip | Output variable: Public IP address |

