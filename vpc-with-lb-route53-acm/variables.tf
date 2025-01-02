variable "name" {

  description = "name for vpc"
  type        = string
  default     = "tftrainingvpc"

}

variable "cidr_block" {
  description = "cidr for vpc"
  type        = string

  default = "10.0.0.0/16"

}

variable "subnet_cidr_block" {
  description = "cidr for public subnet"
  type        = string

  default = "10.0.2.0/24"


}


variable "subnet2_cidr_block" {

  description = "cidr for public subnet"
  type        = string

  default = "10.0.4.0/24"

}

variable "igw_name" {


  description = "name for internet gateway"
  type        = string
  default     = "tftraining_igw"

}


variable "pub_rt_name" {

  description = "name for public route table"
  type        = string
  default     = "tftraining_pub_rt"


}

variable "alb_sg_name" {

  description = "name for alb"
  type        = string
  default     = "tftraining_alb_sg"



}


variable "ec2_sg_name" {

  description = "name for alb"
  type        = string
  default     = "tftraining_ec2_sg"

}
variable "environment" {

  description = "name for environment"
  type        = string
  default     = "training"

}

variable "domain_name" {

  description = "name for the domain name"
  type        = string

  default = "deployfastapi.com"

}


variable "instance_type" {

  description = " choose instance type"
  type        = string

  default = "t2.micro"

}


variable "ec2_name" {
  description = " choose  ec2 instance name"
  type        = string

  default = "tftraining_ec2"


}