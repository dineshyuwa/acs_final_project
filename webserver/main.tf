terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }

  required_version = ">=0.14"
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "terraform_remote_state" "public_subnet" {
  backend = "s3"
  config = {
    bucket = "acs730-project-143871234"
    key    = "project/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_s3_bucket" "website_images" {
  bucket = "${var.prefix}-website-images"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.website_images.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_object" "example_image" {
  bucket = aws_s3_bucket.website_images.bucket
  key    = "project/images/example.jpeg"
  source = "example.jpeg"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid       = "Stmt1686172384560"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::project-website-images/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_images.bucket
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

resource "aws_instance" "private_instance" {

  count           = length(data.terraform_remote_state.public_subnet.outputs.private_subnet_ids)
  ami             = data.aws_ami.latest_amazon_linux.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.assignment.key_name
  security_groups = [aws_security_group.acs730.id]
  subnet_id       = data.terraform_remote_state.public_subnet.outputs.private_subnet_ids[count.index]
  user_data       = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "Hello from ${data.terraform_remote_state.public_subnet.outputs.public_subnet_ids[count.index]}" > /var/www/html/index.html
EOF

  tags = {
    Name        = "WebServer-Private-Group8-${count.index + 1}"
    Environment = "Production"
    Project     = "MyProject"
  }
}

resource "aws_instance" "public_instance" {
  count                       = length(data.terraform_remote_state.public_subnet.outputs.public_subnet_ids)
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.assignment.key_name
  subnet_id                   = data.terraform_remote_state.public_subnet.outputs.public_subnet_ids[count.index]
  associate_public_ip_address = true

  security_groups = count.index == 1 ? [aws_security_group.bastion_sg.id] : [aws_security_group.acs730.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<html><body>" > /var/www/html/index.html
    echo "<h1>Welcome to our site! - Group8</h1>" >> /var/www/html/index.html
    echo "<img src=\"https://ibb.co/dPLWrRZ\">" >> /var/www/html/index.html
    echo "</body></html>" >> /var/www/html/index.html
  EOF

  tags = {
    Name        = count.index == 1 ? "Bastion-Group8" : "WebServer-Public-Group8-${count.index + 1}"
    Environment = "Production"
    Project     = "MyProject"
  }
}

resource "aws_key_pair" "assignment" {
  key_name   = var.prefix
  public_key = file("${var.prefix}.pub")
}

resource "aws_security_group" "acs730" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.public_subnet.outputs.vpc_id

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "SSH access from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.prefix}-EBS"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  description = "Security group for Bastion host allowing SSH access from the internet"
  vpc_id      = data.terraform_remote_state.public_subnet.outputs.vpc_id

  ingress {
    description = "SSH access from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_volume_attachment" "ebs_public_instance" {
  count       = length(aws_instance.private_instance)
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web_ebs[count.index].id
  instance_id = aws_instance.private_instance[count.index].id
}

resource "aws_ebs_volume" "web_ebs" {
  count             = length(aws_instance.private_instance)
  availability_zone = aws_instance.private_instance[count.index].availability_zone
  size              = 40

  tags = {
    "Name" = "${var.prefix}-EBS-${count.index}"
  }
}
