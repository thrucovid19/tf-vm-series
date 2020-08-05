variable "name" {
  default     = "Default"
  type        = string
  description = "Name of the VPC"
}

variable "environment" {
  type        = string
  description = "Name of environment: ex. stg, prod, dev"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the VPC resources"
}

variable "region" {
  default     = "us-east-1"
  type        = string
  description = "Region of the VPC"
}

variable "mgmt_subnet" {
  default     = "192.168.1.0/24"
  type        = string
  description = "CIDR block for the VPC"
}

variable "cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  default     = "us-east-1a", "us-east-1b"
  type        = string
  description = "List of availability zones"
}

variable "public_subnet_cidr_block" {
  default     = "10.0.0.0/24"
  type        = string
  description = "Public subnet CIDR block"
}

variable "management_subnet_cidr_block" {
  default     = "10.0.10.0/24"
  type        = string
  description = "Management subnet CIDR block"
}

variable "private_subnet_cidr_block" {
  default     = "10.0.1.0/24"
  type        = string
  description = "Private subnet CIDR block"
}

variable key_name {
}

