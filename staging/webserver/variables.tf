variable "ami" {
  description = "The ID of the AMI to use for the instance"
  default     = "ami-0c94855ba95c574c8"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Type of the instance"
  type        = string
}


variable "default_tags" {
  default = {
    "Owner" = "CAAacs",
    "App"   = "Web"
  }
  type        = map(any)
  description = "Default tags to be appliad to all AWS resources"
}


variable "prefix" {
  type        = string
  default     = "project"
  description = "Name prefix"
}

variable "env"{
  type = string
  default = "staging"
  description = "env"
}