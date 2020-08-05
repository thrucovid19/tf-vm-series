terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  version                 = "~> 2.0"
  shared_credentials_file = var.credentials
  region                  = var.region
}

resource "aws_key_pair" "thrucovid19" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/terraform-key.pub")
}

locals {
  common_tags = {
    owner = "QA"
  }
}

module "vmseries" {
  source                       = "github.com/thrucovid19/tf-vm-series"
  name                         = "us-west-stage"
  environment                  = "staging"
  key_name                     = aws_key_pair.thrucovid19.key_name
  mgmt_subnet                  = "99.71.211.206/32"
  region                       = var.region
  cidr_block                   = "10.144.0.0/16"
  public_subnet_cidr_block     = "10.144.1.0/24"
  management_subnet_cidr_block = "10.144.10.0/24"
  private_subnet_cidr_block    = "10.144.2.0/24"
  tags                         = local.common_tags
}

output "vm-series-eip" {
  value = module.vmseries.eip
}
