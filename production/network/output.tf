output "public_subnet_ids"{
    value = module.vpc-production.public_subnet_ids
}

output "private_subnet_ids"{
    value = module.vpc-production.private_subnet_ids
}

output "vpc_id"{
    value = module.vpc-production.vpc_id
}