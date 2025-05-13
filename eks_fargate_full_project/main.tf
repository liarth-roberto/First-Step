module "vpc" {
  source  = "./modules/vpc"
  

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

  enable_nat_gateway      = true
  single_nat_gateway      = true
  enable_dns_support      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "iam" {
  source = "./modules/iam"
}

module "eks" {
  source         = "./modules/eks"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnets
  eks_role_arn   = module.iam.eks_role_arn
  node_role_arn  = module.iam.node_role_arn
}

module "cloudwatch" {
  source       = "./modules/cloudwatch"
  cluster_name = module.eks.cluster_name
}

resource "aws_eks_fargate_profile" "default" {
  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = "default"
  pod_execution_role_arn = aws_iam_role.fargate_execution.arn
  subnet_ids             = module.vpc.private_subnets

  selector {
    namespace = "default"
  }

  depends_on = [module.eks]
}

resource "aws_iam_role" "fargate_execution" {
  name = "eks-fargate-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_execution_policy" {
  role       = aws_iam_role.fargate_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}
