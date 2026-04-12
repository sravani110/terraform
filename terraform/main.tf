terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
}

data "vault_kv_secret_v2" "secret-creds" {
  mount = "secret"
  name  = "cloud_user"
}

provider "aws" {
  region     = "us-east-1"
  access_key = data.vault_kv_secret_v2.secret-creds.data["access_key"]
  secret_key = data.vault_kv_secret_v2.secret-creds.data["secret_key"]
}

module "ec2module" {
  source             = "./modules/ec2"
  instance_type      = var.instance_type
  ami                = var.ami
  name               = var.name
  sg_name            = var.sg_name
  cidr_block         = var.cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}
