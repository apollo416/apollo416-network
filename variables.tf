
variable "env" {
  description = "The environment for the network"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prd"], var.env)
    error_message = "Valid values for env are (dev, qa, prd)"
  }
}

variable "rev" {
  description = "The revision based on git commit"
  type        = string
}

variable "aws_kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnets" {
  description = "The CIDR blocks for the private VPC subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
}

variable "vpc_public_subnets" {
  description = "The CIDR blocks for the public VPC subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24", "10.0.6.0/24"]
}

variable "vpc_azs" {
  description = "The availability zones for the VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}