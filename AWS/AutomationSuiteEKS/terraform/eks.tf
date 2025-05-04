/**
 * EKS Terraform Configuration
  * - Creates an EKS cluster with specified version and settings
  * - Configurable node groups and IAM roles
  * - Optional public access and cluster creator admin permissions
  * - Optional secondary CIDR blocks for worker nodes
  */

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  # Give the Terraform identity admin access to the cluster
  # which will allow it to deploy resources into the cluster

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = var.enable_eks_public_access

  # VPC and Subnet settings
  vpc_id = module.vpc.vpc_id
  # subnet_ids = local.secondary_private_subnet_list.*.id
  subnet_ids = local.private_subnet_list.*.id

  # K8s Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }

    aws-efs-csi-driver = {
      most_recent = true
    }

    metrics-server = {
      most_recent = true
    }

    vpc-cni = {
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = var.enable_secondary_cidr ? {
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
          ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
        } : {}
      })
    }
  }
  self_managed_node_groups = {
    "${var.eks_node_group_name}" = {
      # ami_type      = "AL2023_x86_64_STANDARD"
      subnet_ids    = local.private_subnet_list.*.id
      instance_type = var.eks_instance_type
      # Additional IAM policies for the worker nodes
      iam_role_additional_policies = {
        S3Access           = aws_iam_policy.s3_access.arn
        StorageAccess      = aws_iam_policy.storage_access.arn
        LoadbalancerAccess = aws_iam_policy.load_balancer_controller.arn
      }
      min_size = 1
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 3

      # This is not required - demonstrates how to pass additional configuration to nodeadm
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  maxPods: ${var.eks_node_max_pod}
                  shutdownGracePeriod: 30s
                  featureGates:
                    DisableKubeletCloudCredentialProviders: true
          EOT
        }
        # As of 2025-04-28, the following causes an issue when running plan for the first time.
        # content      = <<-EOT
        #   ---
        #   apiVersion: node.eks.aws/v1alpha1
        #   kind: NodeConfig
        #   spec:
        #     cluster:
        #       name: ${var.eks_cluster_name}
        #       apiServiceEndpoint: ${module.eks.cluster_endpoint}
        #       certificateAuthority: ${module.eks.cluster_certificate_authority_data}
        #       cidr: ${module.eks.cluster_service_cidr}
        #     kubelet:
        #       config:
        #         maxPods: 110
        #         shutdownGracePeriod: 30s
        #         featureGates:
        #           DisableKubeletCloudCredentialProviders: true
        # EOT
      ]
      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          ebs = {
            volume_type           = "gp3"
            volume_size           = 256
            delete_on_termination = true
            encrypted             = true
          }
        }
      ]
    }
  }
  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "${var.eks_cluster_name} Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "${var.eks_cluster_name} Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_443 = {
      description = "Allow incoming HTTPS traffic to the EKS worker nodes"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      type        = "ingress"
      cidr_blocks = local.all_private_subnets
    }
  }
  tags = var.tags
}


resource "kubectl_manifest" "eni_config" {
  # Use cidr as the key as it is known befcorehand. This is because the index must be unique and known when plan is exected.
  for_each = {
    for subnet in local.secondary_private_subnet_list : subnet.cidr => subnet
  }

  yaml_body = yamlencode({
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = each.value.az # The availability zone name
    }
    spec = {
      securityGroups = [module.eks.cluster_security_group_id, module.eks.node_security_group_id] # The security group IDs
      subnet         = each.value.id                                                             # The subnet ID
    }
  })
}

/**
 * IAM Policies for EKS worker nodes
 * - EKS module create an IAM role for the worker nodes with the following policies, but this is not enough
 *   - AmazonEKSWorkerNodePolicy
 *   - AmazonEKS_CNI_Policy
 *   - AmazonEC2ContainerRegistryReadOnly
* - The following policies are required for Automation Suite to function.
*/

# S3 access policy
resource "aws_iam_policy" "s3_access" {
  name        = "${var.eks_cluster_name}-s3-access"
  description = "IAM policy for EKS worker nodes to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*",
        ]
      }
    ]
  })
}

# EBS/EFS access policy
resource "aws_iam_policy" "storage_access" {
  name        = "${var.eks_cluster_name}-storage-access"
  description = "Storage access policy for EKS worker nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:CreateTags",
          "elasticfilesystem:CreateFileSystem",
          "elasticfilesystem:DeleteFileSystem",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:CreateMountTarget",
          "elasticfilesystem:DeleteMountTarget",
          "elasticfilesystem:DescribeMountTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Load Balancer Controller policy
resource "aws_iam_policy" "load_balancer_controller" {
  name        = "${var.eks_cluster_name}-lb-controller"
  description = "Load Balancer Controller policy for EKS worker nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ConfigureHealthCheck",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}
output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}
output "region" {
  description = "The region of the EKS cluster"
  value       = var.aws_region
}

