variable "name" {
  type = list(any)
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "cidr_block" {
  type = string
}
variable "public_subnets" { 
  type = list(string)
}

variable "private_subnets" {
   type = list(string) 
}

variable "availability_zones" {
   type = list(string)
}




