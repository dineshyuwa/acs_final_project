module "vpc-development"{
    source = "../../Modules/network"
    env = var.env
    vpc_cidr_block = var.vpc_cidr
}