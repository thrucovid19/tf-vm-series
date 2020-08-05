terraform {
  required_version = ">= 0.12, < 0.13"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # The marketplace product code for all BYOL versions of VM-Series
  availability_zones = data.aws_availability_zones.available.names
  product_code = "6njl1pau431dv1qxipg63mvah"
  management_sg_rules = {
    ssh-from-on-prem = {
      type        = "ingress"
      cidr_blocks = var.mgmt_subnet
      protocol    = "tcp"
      from_port   = "22"
      to_port     = "22"
    }
    https-from-on-prem = {
      type        = "ingress"
      cidr_blocks = var.mgmt_subnet
      protocol    = "tcp"
      from_port   = "443"
      to_port     = "443"
    }
    egress = {
      type        = "egress"
      cidr_blocks = "0.0.0.0/0"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
    }
  }

  public_sg_rules = {
    ingress = {
      type        = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
    }
    egress = {
      type        = "egress"
      cidr_blocks = "0.0.0.0/0"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
    }
  }
  
  private_sg_rules = {
    ingress = {
      type        = "ingress"
      cidr_blocks = aws_vpc.default.cidr_block
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
    }
    egress = {
      type        = "egress"
      cidr_blocks = "0.0.0.0/0"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
    }
  }
}

/*# Find the image for VM-Series
data "aws_ami" "vmseries" {
  most_recent = true
  owners = ["aws-marketplace"]
  filter {
    name   = "owner-alias"
    values = ["aws-marketplace"]
  }

  filter {
    name   = "product-code"
    values = [local.product_code]
  }

  filter {
    name   = "name"
    # Using the asterisc, this finds the latest release in the mainline version
    values = ["PA-VM-AWS-${var.vmseries_version}*"]
  }
}*/

data "aws_ami" "ubuntu_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

# Create a VPC 

resource "aws_vpc" "default" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "${var.name} VPC",
      Environment = var.environment
    },
    var.tags
  )
}

# Creates an Internet gateway 

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name        = "${var.name} IGW",
      Environment = var.environment
    },
    var.tags
  )
}

# Create a public subnet

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "${var.name} PublicSubnet",
      Environment = var.environment
    },
    var.tags
  )
}

# Create a management subnet

resource "aws_subnet" "management" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.management_subnet_cidr_block
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "${var.name} ManagementSubnet",
      Environment = var.environment
    },
    var.tags
  )
}

# Create a private subnet 

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = local.availability_zones[0]

  tags = merge(
    {
      Name        = "${var.name} PrivateSubnet",
      Environment = var.environment
    },
    var.tags
  )
}

# Create a management route table

resource "aws_route_table" "management" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name        = "${var.name} ManagementRouteTable",
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "management" {
  route_table_id         = aws_route_table.management.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a public route table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name        = "${var.name} PublicRouteTable",
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a private route table

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name        = "${var.name} PrivateRouteTable",
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.private.id
}

# Route table association for all subnets

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "management" {
  subnet_id      = aws_subnet.management.id
  route_table_id = aws_route_table.management.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create a public security group

resource "aws_security_group" "public" {
  name        = "${var.name} Firewall-Public"
  description = "Allow inbound applications from the internet"
  vpc_id      = aws_vpc.default.id
}

resource "aws_security_group_rule" "public" {
  for_each          = local.public_sg_rules
  security_group_id = aws_security_group.public.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr_blocks]
}

# Create a management security group

resource "aws_security_group" "management" {
  name        = "${var.name} Firewall-Mgmt"
  description = "Allow inbound management to the firewall"
  vpc_id      = aws_vpc.default.id
}

resource "aws_security_group_rule" "management" {
  for_each          = local.management_sg_rules
  security_group_id = aws_security_group.management.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr_blocks]
}

# Create a private security group

resource "aws_security_group" "private" {
  name        = "${var.name} Firewall-Private"
  description = "Allow inbound traffic to the firewalls private interfaces"
  vpc_id      = aws_vpc.default.id
}

resource "aws_security_group_rule" "private" {
  for_each          = local.private_sg_rules
  security_group_id = aws_security_group.private.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr_blocks]
}

# Create management network interface

resource "aws_network_interface" "management" {
  subnet_id         = aws_subnet.management.id
  private_ips       = [cidrhost(var.management_subnet_cidr_block,10)]
  security_groups   = [aws_security_group.management.id]
  source_dest_check = true

  tags = merge(
    {
      Name        = "${var.name} Management ENI",
      Environment = var.environment
    },
    var.tags
  )
}

# Create an EIP and associate it to the management interface

resource "aws_eip" "management" {
  vpc               = true
  network_interface = aws_network_interface.management.id

  tags = merge(
    {
      Name        = "${var.name} Maanagement EIP",
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_instance.this,
  ]
}

# Create public network interface

resource "aws_network_interface" "public" {
  subnet_id         = aws_subnet.public.id
  private_ips       = [cidrhost(var.public_subnet_cidr_block,10)]
  security_groups   = [aws_security_group.public.id]
  source_dest_check = false

  tags = merge(
    {
      Name        = "${var.name} Public ENI",
      Environment = var.environment
    },
    var.tags
  )
}

# Create an EIP and associate it to the public interface

resource "aws_eip" "public" {
  vpc               = true
  network_interface = aws_network_interface.public.id

  tags = merge(
    {
      Name        = "${var.name} Public EIP",
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_instance.this,
  ]
}

# Create private network interface

resource "aws_network_interface" "private" {
  subnet_id         = aws_subnet.private.id
  private_ips       = [cidrhost(var.private_subnet_cidr_block,10)]
  security_groups   = [aws_security_group.private.id]
  source_dest_check = false

  tags = merge(
    {
      Name        = "${var.name} Private ENI",
      Environment = var.environment
    },
    var.tags
  )
}

# Create the vm-series instance

resource "aws_instance" "this" {
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  //iam_instance_profile                 = var.bootstrap_profile
  //user_data                            = base64encode(join("", list("vmseries-bootstrap-aws-s3bucket=", var.bootstrap_s3bucket)))

  ebs_optimized = true
  ami           = data.aws_ami.ubuntu_linux.image_id
  instance_type = "t3.small"
  key_name      = var.key_name

  monitoring = false

  root_block_device {
    delete_on_termination = "true"
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.management.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.public.id
  }
 
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.private.id
  }

  tags = merge(
    {
      Name        = "${var.name} Instance",
      Environment = var.environment
    },
    var.tags
  )
}