variable "project"        { type = string }
variable "aws_region"     { type = string  default = "eu-central-1" }
variable "instance_type"  { type = string  default = "t3.micro" }
variable "key_name"       { type = string }         # EC2 Key Pair անուն
variable "vpc_id"         { type = string }         # եթե թափանցիկ VPC չունես, կարող եմ ավելացնել VPC ստեղծում
variable "public_subnet_id" { type = string }       # public subnet ID
variable "allow_ssh_cidr" { type = string  default = "0.0.0.0/0" }
