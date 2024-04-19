variable "vpc_cidr" {
  default     = "10.3.0.0/16"
  type        = string
  description = "VPC to host static web site"
}

variable "env" {
  default     = "staging"
  type        = string
  description = "env"
}