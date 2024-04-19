variable "vpc_cidr" {
  default     = "10.2.0.0/16"
  type        = string
  description = "VPC to host static web site"
}

variable "env" {
  default     = "development"
  type        = string
  description = "env"
}