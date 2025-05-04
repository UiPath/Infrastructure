
# Terraform for Automation Suite on EKS

This guide demonstrates how to deploy the entire infrastructure required for [**UiPath Automation Suite on EKS**](https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-eks-aks/automation-suite-overview) using Terraform. It also walks you through the steps to deploy Automation Suite on top of the EKS cluster.

 > **Disclaimer:** :warning: This guide is an example and should only be used for testing Automation Suite.

## Infrastructure Components

The following infrastructure components will be provisioned:

- EKS Cluster
- RDS SQL Server
- ElastiCache OSS Redis
- S3 Bucket
- VPC (subnets, route tables, internet gateway, NAT gateway)
- (Optional) EC2 Windows Bastion Host

---

## Prerequisites

Ensure the following tools are installed on your machine:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

---

## Preparing Terraform

Clone the repository and navigate to the Terraform folder:

```bash
git clone https://github.com/UiPath/Infrastructure
cd AWS/AUTOMATIONSUITEEKS/terraform
```

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the required variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Example `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
s3_bucket_name = "globally-unique-bucket-name"
rds_password = "your-secure-rds-password"
elasticache_auth_token = "your-secure-redis-auth-token"

# Optional - Deploy EC2 Bastion Host
create_ec2_instance = true
is_ec2_public = true
get_ec2_password = true
```

---

## Deploying the Infrastructure

Initialize, plan, and apply Terraform:

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars --auto-approve
```

> **Note:** Review the `terraform plan` output carefully and fix any errors before applying.

Take note of the Terraform output values as they will be needed later.

Example output:

```bash
eks_cluster_name = "main-eks-cluster"
eks_cluster_endpoint = "https://xxxxx.eks.amazonaws.com"
db_instance_address = "main-mssql.xxxxx.rds.amazonaws.com"
elasticache_primary_endpoint = "master.main-redis-cluster.xxxxx.cache.amazonaws.com"
ec2_instance_public_ip = "xx.xx.xx.xx"
...
```

---

## Preparing for Automation Suite Installation

### :one: Enable `kubectl` access

```bash
aws eks --region <aws-region> update-kubeconfig --name <eks-cluster-name>
```

### :two: Verify cluster access

```bash
kubectl get nodes
```

Example output:

```bash
NAME                                        STATUS   ROLES    AGE     VERSION
ip-10-0-10-149.us-west-1.compute.internal   Ready    <none>   7h32m   v1.31.7-eks-473151a
```

### :three: Create StorageClass for EBS volumes

```bash
kubectl apply -f - <<EOF
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl get sc
```

Expected output:

```bash
NAME               PROVISIONER             RECLAIMPOLICY   ...
ebs-sc (default)   ebs.csi.aws.com         Delete          ...
gp2                kubernetes.io/aws-ebs   Delete          ...
```

---

## Downloading Automation Suite Files

```bash
wget https://download.uipath.com/uipathctl/2024.10.3/uipathctl-2024.10.3-linux-amd64.tar.gz
wget https://download.uipath.com/automation-suite/2024.10.3/versions.json
tar -xvf uipathctl-2024.10.3-linux-amd64.tar.gz
chmod +x uipathctl
```

> **Note:** If you are using Windows or Mac, please download the corresponding version of `uipathctl` from the [UiPath download page](https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-eks-aks/downloading-the-installation-packages).

---

## Creating `input.json`

Prepare `input.json` with your own values.  
Replace placeholders marked by `<>`. Only Orchestrator and Platform components are enabled in this example. Should you like to customize the components, please refer to [Conifguring input.json](https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-eks-aks/configuring-inputjson) for more details.

<details>

  <summary>> See the full input.json example </summary>

  ```json
  {
    "kubernetes_distribution": "eks",
    "install_type": "online",
    "profile": "ha",
    "fqdn": "<fqdn>",
    "admin_username": "admin",
    "admin_password": "<admin_password>",
    "telemetry_optout": true,
    "fips_enabled_nodes": false,
    "fabric": {
      "redis": {
        "hostname": "<elasticache_primary_endpoint>",
        "password": "<elasticache_auth_token>",
        "port": 6379,
        "tls": true
      }
    },
    "external_object_storage": {
      "enabled": true,
      "use_instance_profile": true,
      "storage_type": "s3",
      "port": 443,
      "region": "<aws_region>"
    },
    "ingress": {
      "service_annotations": {
        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol": "ssl",
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type": "ip",
        "service.beta.kubernetes.io/aws-load-balancer-scheme": "internal",
        "service.beta.kubernetes.io/aws-load-balancer-type": "nlb",
        "service.beta.kubernetes.io/aws-load-balancer-internal": "true",
        "service.beta.kubernetes.io/aws-load-balancer-subnets": "<private_subnet_id1>,<private_subnet_id2>,<private_subnet_id3>",
        "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags": "Owner=tatsuya.emoto@uipath.com,Project=Service Fabric"
      }
    },
    "sql": {
      "create_db": true,
      "server_url": "<db_instance_address>",
      "port": "1433",
      "username": "<db_instance_username>",
      "password": "<db_instance_password>"
    },
    "orchestrator": {
      "enabled": true,
      "external_object_storage": {
        "bucket_name": "<s3_common_bucket_id>"
      }
    },
    "processmining": {
      "enabled": false
    },
    "insights": {
      "enabled": false
    },
    "automation_hub": {
      "enabled": false
    },
    "automation_ops": {
      "enabled": false
    },
    "aicenter": {
      "enabled": false
    },
    "documentunderstanding": {
      "enabled": false
    },
    "test_manager": {
      "enabled": false
    },
    "action_center": {
      "enabled": false
    },
    "apps": {
      "enabled": false
    },
    "integrationservices": {
      "enabled": false
    },
    "studioweb": {
      "enabled": false
    },
    "dataservice": {
      "enabled": false,
    },
    "asrobots": {
      "enabled": false
    },
    "storage_class": "ebs-sc",
    "storage_class_single_replica": "efs-sc",
    "platform": {
      "enabled": true,
      "external_object_storage": {
        "bucket_name": "<s3_common_bucket_id>"
      }
    },
    "namespace": "uipath",
    "sql_connection_string_template": "Server=tcp:<db_instance_address>,1433;Initial Catalog=DB_NAME_PLACEHOLDER;Persist Security Info=False;User Id=<db_instance_username>;Password='<db_instance_password>';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;Max Pool Size=100;MultiSubnetFailover=True;",
    "sql_connection_string_template_jdbc": "jdbc:sqlserver://<db_instance_address>:1433;database=DB_NAME_PLACEHOLDER;user=<db_instance_username>;password={<db_instance_password>};encrypt=true;trustServerCertificate=true;loginTimeout=30;multiSubnetFailover=true;hostNameInCertificate=<db_instance_address>",
    "sql_connection_string_template_odbc": "SERVER=<db_instance_address>,1433;DATABASE=DB_NAME_PLACEHOLDER;DRIVER={ODBC Driver 17 for SQL Server};UID=<db_instance_username>;PWD={<db_instance_password>};Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;hostNameInCertificate=<db_instance_address>;MultiSubnetFailover=YES",
    "sql_connection_string_template_sqlalchemy_pyodbc": "mssql+pyodbc://<db_instance_username>:<db_instance_password>@<db_instance_address>:1433/DB_NAME_PLACEHOLDER?driver=ODBC+Driver+17+for+SQL+Server",
    "exclude_components": [
        "alerts",
        "auth",
        "logging",
        "monitoring",
        "velero"
    ]
  }
```

</details>

---

## Creating Databases

```bash
./uipathctl prereq create input.json --versions versions.json
```

Example success output:

```bash
✔ [SQL_DATABASE_CREATED] Created SQL database AutomationSuite_Platform
✔ [SQL_DATABASE_CREATED] Created SQL database AutomationSuite_Orchestrator
```

---

## Validate Prerequisites

```bash
./uipathctl prereq run input.json --versions versions.json
```

### ⚡️ Ignore these errors for now (they will be fixed later)

```bash
- ❌ [DNS(FQDN=...)]
- ❌ [STORAGECLASS(NAME=STORAGE_CLASS_SINGLE_REPLICA)]
- ❌ [ECHO_SERVER_ACCESS] Echo server is not expected to be accessible from curl pod
- ❌ [INGRESS_LB_CREATION_FAILED] echo-service-vnvmp service failed to be ready, error - timed out waiting for the condition
- ❌ [CLIENT_FAILED] Failed to create metrics client
...
```

---

## Installing Automation Suite

```bash
./uipathctl manifest apply input.json --versions versions.json
```

---

## Verifying Istio and Load Balancer

Associate the `EXTERNAL-IP` (CNAME) with your `FQDN` in DNS to access the Automation Suite Web UI.

```bash
kubectl get svc istio-ingressgateway -n istio-system
```

Example output:

```bash
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP
istio-ingressgateway   LoadBalancer   172.20.9.249   xxxxx.elb.amazonaws.com
```

> **Note:** The LoadBalancer may take a few minutes to be provisioned. If it shows `pending`, wait a bit and check again.

---

## Installation Completion

After 20–30 minutes, the installation should complete. You should see:

```bash
base created
istiod created
...
platform created
orchestrator created
```

> **Note:** :warning: The installation may take longer depending on your AWS region and network speed. Or, it may fail due to a various reasons. In that case, please check the logs, state of the pods, and use [Troubleshooting tools](https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-eks-aks/troubleshooting-tools) to identify the issues.

---

## Accessing Automation Suite Web UI via EC2 Bastion Host

:one: RDP into the EC2 Bastion Host.
:two: Retrieve the password:

```bash
terraform output ec2_instance_password
```

:three: Open the Automation Suite Web UI using your `FQDN`.
:four: Refer to [UiPath Documentation](https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-eks-aks/accessing-automation-suite#accessing-automation-suite-general-interface) for the default login password.

---

## Destroying the Infrastructure

:one: Remove `istio-ingressgateway` service because it provisions a network load balancer, not Terraform. Unless you remove it prior, Terraform destroy will fail.

```bash
kubectl delete svc istio-ingressgateway -n istio-system
```

:two: Destroy the infrastructure:

```bash
terraform destroy -var-file=terraform.tfvars --auto-approve
```

---

## Final Notes

- Ensure the DNS records are correctly pointing to your Istio LoadBalancer.
- Some errors related to DNS or storage class may occur initially and can be resolved after installation.
- Monitor installation progress using `kubectl`.

---

## Support and Feedback

This code is maintained by UiPath Infrastructure team. UiPath does not provide any support for this code. If you have any questions or feedback, please open an issue in this repository, 
