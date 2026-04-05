data "aws_iam_role" "jenkins-iam" {
  name = "jenkins"
}

data "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins"
}

resource "aws_instance" "ec2" {
 tags = {
  Name = var.name
 }
 ami = var.ami
 instance_type = var.instance_type
 key_name = aws_key_pair.key.id
 subnet_id = aws_subnet.public[0].id
 vpc_security_group_ids = [aws_security_group.sg.id]
 iam_instance_profile = data.aws_iam_instance_profile.jenkins_profile.name
 user_data = <<-EOF
    #!/bin/bash
  
    # Install Jenkins
    sudo dnf update -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf upgrade
    sudo dnf install java-17-amazon-corretto -y
    sudo dnf install jenkins git -y
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    sudo systemctl status jenkins
    sudo usermod -aG docker jenkins

    # Install Docker
    sudo yum install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

  EOF

}

resource "aws_key_pair" "key" {
  key_name   = "keypair"
  public_key = file("~/.ssh/keypair.pub")
}

resource "aws_security_group" "sg" {
  name = var.sg_name
  vpc_id = aws_vpc.vpc-1.id
  ingress {
      from_port   = "0"
      to_port     = "0"
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "vpc-1" {
  tags = {
    Name = "projectvpc"
  }
  cidr_block = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  tags = {
    Name = "${var.availability_zones[count.index]}-public"
  }
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc-1.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  tags = {
    Name = "${var.availability_zones[count.index]}-private"
  }
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.vpc-1.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
}

resource "aws_internet_gateway" "igw" {
  tags = {
    Name = "igw"
  }
  vpc_id = aws_vpc.vpc-1.id
}

resource "aws_route_table" "public-rt" {
  tags = {
    Name = "RT-Public"
  }
  vpc_id = aws_vpc.vpc-1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat-gw" {
  tags = {
    Name = "nat-gateway"
  }
  subnet_id = aws_subnet.public[0].id
  allocation_id = aws_eip.eip.id
}

resource "aws_route_table" "private-rt" {
  tags = {
    Name = "RT-Private"
  }
  vpc_id = aws_vpc.vpc-1.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
}

resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-rt.id
}


resource "aws_route_table_association" "private_association" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_ecr_repository" "example" {
name = "img-repo"
image_tag_mutability = "MUTABLE"
image_scanning_configuration {
scan_on_push = true
}
}

#IAM Role for Cluster Control Plane 
resource "aws_iam_role" "eks_cluster_role" {

  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

#EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
    
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy
  ]
}

#IAM Role for EKS Managed Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#EKS Managed Node Group
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "managed-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t2.micro"]
  tags = { Name = "eks-worker-node" }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.worker_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.worker_node_AmazonEC2ContainerRegistryReadOnly
  ]
}