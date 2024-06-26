output "public_subnet_ids"{
    value = module.vpc-staging.public_subnet_ids
}

output "private_subnet_ids"{
    value = module.vpc-staging.private_subnet_ids
}

output "vpc_id"{
    value = module.vpc-staging.vpc_id
}