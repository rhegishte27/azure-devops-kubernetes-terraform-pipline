# aws --version
# aws eks --region us-east-1 update-kubeconfig --name rupeshh-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-rupesh01
# AKIAYIJETJ6IAFBTXPU5


terraform {
  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "ap-south-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnet_ids" "subnets" {
  vpc_id = aws_default_vpc.default.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "rupeshh-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "rupeshh-cluster"
  cluster_version = "1.14"
  subnets         = ["subnet-099f6465e0c5a4294", "subnet-02a5d1fb27edea60e"] #CHANGE
  #subnets = data.aws_subnet_ids.subnets.ids
  vpc_id          = aws_default_vpc.default.id

  #vpc_id         = "vpc-1234556abcdef"

  node_groups = [
    {
      instance_type = "t2.micro"
      max_capacity  = 3
      desired_capacity = 1
      min_capacity  = 1
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.rupeshh-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.rupeshh-cluster.cluster_id
}


# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments 
# and services in default namespace
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region  = "ap-south-1"
}