module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           = "my-ec2-cluster"
  instance_count = 2

  ami                    = "ami-0c5204531f799e0c6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "vmseries-a" {
  source = "../modules/vmseries/"
  instance_name = "vmseries-a"
  aws_key = data.terraform_remote_state.panorama.outputs.key_pair
  mgmt_security_group = aws_security_group.mgmt.id
  mgmt_subnet_id = aws_subnet.mgmt_subnet_primary.id
  mgmt_subnet_block = aws_subnet.mgmt_subnet_primary.cidr_block
  public_security_group = aws_security_group.public.id
  public_subnet_id = aws_subnet.public_subnet_primary.id
  public_subnet_block = aws_subnet.public_subnet_primary.cidr_block
  private_security_group = aws_security_group.private.id
  private_subnet_id = aws_subnet.private_subnet_primary.id
  private_subnet_block = aws_subnet.private_subnet_primary.cidr_block
  bootstrap_s3bucket = aws_s3_bucket.vmseries-a.id
  bootstrap_profile = aws_iam_instance_profile.bootstrap_profile.id
  private_route_table = aws_route_table.private-a.id
}