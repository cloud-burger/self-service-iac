provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  }
}

provider "kubectl" {
  apply_retry_count      = 15
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  }
}

module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.33"
  depends_on                               = [module.vpc]
  cluster_name                             = local.name
  cluster_version                          = local.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  eks_managed_node_group_defaults = {
    capacity_type = "SPOT"
    iam_role_additional_policies = {
      dynamoDB = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
      SQS      = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
    }
  }
  eks_managed_node_groups = {
    initial = {
      instance_types = ["m5.large"]

      min_size     = 1
      max_size     = 4
      desired_size = 1
    }
  }
  # EKS Addons
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
  tags = local.tags
}

locals {
  namespace_list = {
    istio = "istio-system"
    self-service = "self-service"
  }
}

resource "kubernetes_namespace_v1" "istio_system" {
  for_each = local.namespace_list
  depends_on = [module.eks]
  metadata {
    name = each.value
  }
}

resource "kubectl_manifest" "istio_gateway" {
  depends_on = [kubernetes_namespace_v1.istio_system]
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: self-service-gateway
  namespace: self-service
spec:
  selector:
    istio: ingressgateway
  servers:
    - hosts:
        - "*"
      port:
        name: http
        number: 80
        protocol: HTTP
    - hosts:
        - "*"
      port:
        name: http-443
        number: 443
        protocol: HTTP
YAML
}