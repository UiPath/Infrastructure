# UIPath Orchestrator multi-node deployment

## In general
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure

## Use managed services
Set variables create_redis and/or create_sql to "true" and use managed versions of SQLServer and Redis.

## Input parameters

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| project | GCP project name | String | - | yes |
| instance_count | starting count if instances | Int | 1 | no |
| max_instances | max count of instances | Int | 3 | no |
| vm_username | VM local username| String | uioadmin | yes |
| vm_password | VM local password | String | Password12 | yes |
| image | Windows Server image to use | String | windows-server-2019-dc-v20200114 | yes |
| orchestrator_version | UIPath Orchestrator release | String | 19.4.4 | yes |
| create_sql | create SQLServer instance | Bool | false | yes |
| sql_root_pass | admin user password, required for SQLServer deploy | String | - | yes, with create_sql |
| orchestrator_databaseservername | existing SQLServer address | String | sqlhost | yes |
| orchestrator_databasename | existing SQLServer DB name | String | uipath | yes |
| orchestrator_databaseusername | existing SQLServer username | String | sa | yes |
| orchestrator_databaseuserpassword | existing SQLServer password, will be used for newly-created user, in case of "create_sql" = "true" | String | Password12 | yes |
| create_redis | create Memorystore instance | String | true | yes |
| redis_host | Redis host, if already created will be used, ignored in case of "create_redis" = "true" | String | - | yes |
| orchestrator_domain | domain name, which will be used in TLS certificate, See [docs](https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs) | String | - | yes |
| deploy_id | Suffix, added to resource names | String | dev | yes |
