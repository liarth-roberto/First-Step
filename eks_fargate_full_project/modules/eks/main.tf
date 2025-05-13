resource "aws_eks_cluster" "eks" {
  name     = "eks-cluster"
  role_arn = var.eks_role_arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [var.eks_role_arn]
}

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}
