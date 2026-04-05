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
