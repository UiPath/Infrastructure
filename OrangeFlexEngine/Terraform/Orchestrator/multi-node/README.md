# Terraform & FE => ♥ UiPath Orchestrator.
Steps to provision Orchestrator on FE:
1. Install terraform  v0.12.12 (https://learn.hashicorp.com/terraform/getting-started/install.html).
2. Complete the variables.tf file (see inputs below). For Orchestrator hardware requirements and ECS types, check : https://docs.prod-cloud-ocb.orange-business.com/en-us/ecs_dld/index.html  and https://orchestrator.uipath.com/docs/hardware-requirements-orchestrator.
3. Change directory to path of the Orchestrator plan (cd {}/OrangeFlexEngine/Terraform/Orchestrator/multi-node).
4. Fill your openshift credentials in passowrds file  --see password.mock
5. Source that file on a linux VM    
5. Run : ` terraform init `
6. Run : ` terraform plan `
7. Check the plan of the resources to be deployed and type ` yes ` if you agree with the plan.` terrafrom apply `
8. Wait 20-30 mins and enjoy! The password of the Orchestrator is the password used to ` orchestrator_password ` variable.

## Terraform version
Terraform v0.12.12

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| win_flavor | Orchestrator Instance type. | string | `"s3.2xlarge.2"` | yes |
| environment | Environment name, used as prefix to tag the name of the resources. | string | `"dev"` | yes |
| application | Application stack name, used as prefix to tag the name of the resources. | string | `"OrchestratorStack"` | yes |
| db\_username | RDS master user name. | string | `"devawsdb"` | yes |
| db\_password | RDS Master password. | string | `"!vfdgva%gsd"` | yes |
| db\_name | RDS database name. | string | `"awstest"` | yes |
| rds\_allocated\_storage | The allocated storage in gigabytes. | string | `"600"` | yes |
| rds\_instance\_class | The instance type of the RDS instance. | string | `"rds.mssql.c2.4xlarge.ha"` | yes |
| rds\_multi\_az | Specifies if the RDS instance is multi-AZ. | string | `"false"` | yes |
| skip\_final\_snapshot | Determines whether a final DB snapshot is created before the DB instance is deleted. | string | `"true"` | yes |
| orchestrator\_password | Orchestrator Administrator password to login in Default and Host Tennant. | string | `"0rCh35Tr@tor!"` | yes |
| orchestrator\_version | Orchestrator Version. | string | `"19.4.4"` | yes |
| admin\_password | Windows Administrator password used to login in the provisioned VMs. | string | `"WinP@55!"` | yes |
| orchestrator\_passphrase | Orchestrator Passphrase used to generate NuGet API keys, App encryption key and machine keys. | string | `"!asfgre2%gsd"` | yes |
| orchestrator\_license | Orchestrator license code. The license created with regutil. | string | `"TheLicenseCreatedwithRegUtil"` | yes |
