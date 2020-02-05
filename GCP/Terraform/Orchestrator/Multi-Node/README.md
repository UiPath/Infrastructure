# Use managed services
Set variables create_redis and/or create_sql to "true" and use managed versions of SQLServer and Redis.

# Input parameters
project - GCP project name

instance_count - starting count if instances in scalable group
max_instances - max count of instances in group

vm_username - VM local username
vm_password - VM local password

image - Windows Server image to use
orchestrator_version - UIPath Orchestrator release

create_sql - create SQLServer instance
sql_root_pass - admin user password, required for SQLServer deploy

orchestrator_databaseservername - existing SQLServer address
orchestrator_databasename - existing SQLServer DB name
orchestrator_databaseusername - existing SQLServer username
orchestrator_databaseuserpassword - existing SQLServer password, will be used for newly-created user, in case of "create_sql" = "true"

create_redis - create Memorystore instance
redis_host - Redis host, if already created will be used, ignored in case of "create_redis" = "true"

orchestrator_domain - domain name, which will be used in TLS certificate, see https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs
