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

module "vmseries" {
  source      = "github.com/thrucovid19/tf-vm-series"
  name        = "Test"
  environment = "testing"
  key_name    = aws_key_pair.thrucovid19.key_name
  mgmt_subnet = "192.168.1.0/24"
}

output "vm-series-eip" {
  value = module.vmseries.eip
}
