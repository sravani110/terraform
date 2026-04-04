/*provider "vault" {
  address = "http://127.0.0.1:8200"
}

data "vault_kv_secret_v2" "awscreds" {
  mount = "aws"
  name = "creds"
}*/


provider "aws" {
  region = "us-east-1"
  #access_key = data.vault_kv_secret_v2.awscreds.data["access_key"]
  #secret_key = data.vault_kv_secret_v2.awscreds.data["secret_key"]
}