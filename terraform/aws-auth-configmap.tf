/*resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: arn:aws:iam::905418270714:role/jenkins-iam
  username: jenkins
  groups:
    - system:masters
EOF
  }

  depends_on = [
    aws_eks_cluster.eks
  ]
}*/