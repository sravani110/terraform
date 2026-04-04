name               = ["jenkins", "agent"]
sg_name            = "sec-1"
ami                = "ami-02dfbd4ff395f2a1b"
instance_type      = "t2.medium"
cidr_block         = "10.0.0.0/16" 
public_subnets     = ["10.0.0.0/25", "10.0.0.128/25"]
private_subnets    = ["10.0.1.0/25", "10.0.1.128/25"] 
availability_zones = ["us-east-1a", "us-east-1b"] 
