variable "project"        { type = string }
variable "aws_region"     { type = string  default = "eu-north-1" }
variable "instance_type"  { type = string  default = "t3.micro" }
variable "key_name"       { type = testBDG }         # EC2 Key Pair անուն
variable "vpc_id"         { type = vpc-0cd0ec95473967e71 }         # եթե թափանցիկ VPC չունես, կարող եմ ավելացնել VPC ստեղծում
variable "public_subnet_id" { type = subnet-01b588c348b24bdeb}       # public subnet ID
variable "allow_ssh_cidr" { type = string  default = "13.62.128.212" }
