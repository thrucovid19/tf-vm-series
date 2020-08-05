variable instance_type {
  description = "Instance type for VM-Series"
  default = "m4.2xlarge"
}

variable vmseries_version {
  description = "Mainline version for VM-Series. Does not define a specific release number."
  default = "9.1"
}

variable aws_key {
}

variable instance_name {
}

variable mgmt_security_group {
}

variable mgmt_subnet_id {
}

variable mgmt_subnet_block {
}

variable public_security_group {
}

variable public_subnet_id {
}

variable public_subnet_block {
}

variable private_security_group {
}

variable private_subnet_id {
}

variable private_subnet_block {
}

variable bootstrap_profile {
}

variable bootstrap_s3bucket {
}

variable private_route_table {
}
