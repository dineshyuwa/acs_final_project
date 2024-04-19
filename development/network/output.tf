output "public_subnet_ids"{
    value = module.vpc-development.public_subnet_ids
}

output "private_subnet_ids"{
    value = module.vpc-development.private_subnet_ids
}

output "vpc_id"{
    value = module.vpc-development.vpc_id
}