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