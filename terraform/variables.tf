variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "private_subnet_a_cidr" {
  type    = string
  default = "10.20.10.0/24"
}

variable "private_subnet_b_cidr" {
  type    = string
  default = "10.20.20.0/24"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "bedrock_model_id" {
  type    = string
  default = "apac.amazon.nova-micro-v1:0"
}
