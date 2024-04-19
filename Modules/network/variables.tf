variable "vpc_cidr_block" {
  default     = "10.1.0.0/16"
  type        = string
  description = "VPC to host static web site"
}


variable "availability_zones" {
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  type        = list(string)
  description = "availability_zones"
}

variable "env" {
  default     = "development"
  type        = string
  description = "env"
}