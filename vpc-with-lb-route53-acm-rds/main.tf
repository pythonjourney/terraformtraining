#Terraform script to create vpc, subnets, elb, route53, acm


#data source or ami

data "aws_availability_zones" "available" {}


data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "tftrainingvpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}"

  }
}

resource "aws_subnet" "tftraining_public_subnet1" {

  vpc_id            = aws_vpc.tftrainingvpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true

}

resource "aws_subnet" "tftraining_public_subnet2" {

  vpc_id            = aws_vpc.tftrainingvpc.id
  cidr_block        = var.subnet2_cidr_block
  availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = true

}

#creating private subnet1

resource "aws_subnet" "tftraining_private_subnet1" {
  vpc_id = aws_vpc.tftrainingvpc.id
  cidr_block = var.private_subnet1_cidr_block
  availability_zone = data.aws_availability_zones.available.names[0]
   map_public_ip_on_launch = false
  
}

resource "aws_subnet" "tftraining_private_subnet2" {
  vpc_id = aws_vpc.tftrainingvpc.id
  cidr_block = var.private_subnet2_cidr_block
  availability_zone = data.aws_availability_zones.available.names[1]
   map_public_ip_on_launch = false
  
}
#creating DB Subnet group for  RDS
resource "aws_db_subnet_group" "tftraining_dbsubnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.tftraining_private_subnet1.id, aws_subnet.tftraining_private_subnet2.id]

  tags = {
    Name = "${var.dbsubnet_groupname}"
  }
}

#creating and attaching internet gateway to vpc

resource "aws_internet_gateway" "tftraining_igw" {
  vpc_id = aws_vpc.tftrainingvpc.id

  tags = {
    Name = "${var.igw_name}"
  }
}

#ceating Route Table

resource "aws_route_table" "tftraining_public_rt" {
  vpc_id = aws_vpc.tftrainingvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tftraining_igw.id
  }



  tags = {
    Name = "${var.pub_rt_name}"
  }
}

resource "aws_route_table_association" "tftraining_public_subnet_assoc1" {
  subnet_id      = aws_subnet.tftraining_public_subnet1.id
  route_table_id = aws_route_table.tftraining_public_rt.id


}

resource "aws_route_table_association" "tftraining_public_subnet_assoc2" {
  subnet_id      = aws_subnet.tftraining_public_subnet2.id
  route_table_id = aws_route_table.tftraining_public_rt.id


}


#creating alb security group 

resource "aws_security_group" "tftraining_alb_sg" {
  name        = "tftraining_alb_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.tftrainingvpc.id

  ingress {



    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]

  }


  ingress {



    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]

  }


  egress {



    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }




  tags = {
    Name = "${var.alb_sg_name}"
  }
}





#creating EC2 for security group

resource "aws_security_group" "tftraining_ec2_sg" {
  name        = "tftraining_ec2_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.tftrainingvpc.id

  ingress {



    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]

  }


  ingress {



    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]

  }


  egress {



    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }




  tags = {
    Name = "${var.ec2_sg_name}"
  }
}

#Creating security group for RDS

resource "aws_security_group" "tftraining_rds_sg" {
  name        = "tftraining_rds_sg"
  description = "Allow 3306 inbound traffic for tftraining_ec2_sg and all outbound traffic"
  vpc_id      = aws_vpc.tftrainingvpc.id

  ingress {



    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    security_groups = [aws_security_group.tftraining_ec2_sg.id]

  }


  


  egress {



    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }




  tags = {
    Name = "${var.rds_sg_name}"
  }
}


#creating EC2 instance

resource "aws_instance" "tftraining_ec2_server" {

  instance_type          = var.instance_type
  ami                    = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [aws_security_group.tftraining_ec2_sg.id]
  subnet_id = aws_subnet.tftraining_public_subnet1.id
  key_name = "tfdec30"


  connection {
    type        = "ssh"
    user        = "ubuntu"                                  # Default user for Ubuntu AMIs
    private_key = file("C:/Users/Hi/Downloads/tfdec30.pem") # Path to your private key
    host        = self.public_ip

  }

  provisioner "remote-exec" {

    inline = [

      
           "sleep 30",
           "sudo apt update -y",
           "sudo apt install docker.io -y",
           "sudo systemctl start docker",
           "sudo systemctl enable docker",
           "sudo usermod -aG docker ubuntu",
           "sudo apt-get install -y mysql-client",
  
           "sudo docker pull wordpress -y",
     "sudo docker run -d --name wordpress -e WORDPRESS_DB_HOST=${aws_db_instance.tftraining_rds_instance.endpoint}:3306 -e WORDPRESS_DB_USER=${var.dbusername} -e WORDPRESS_DB_PASSWORD=${var.dbpassword} -e WORDPRESS_DB_NAME=${var.dbname} -p 80:80 wordpress:latest"

    ]
             

              

  }


  tags = {

    Name = "${var.ec2_name}"
  }

   depends_on = [aws_db_instance.tftraining_rds_instance]
}



resource "aws_db_instance" "tftraining_rds_instance" {
    identifier            = "tftrainingdb"
  allocated_storage    = 20
  db_name              = var.dbname
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.dbusername
  password             = var.dbpassword
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.tftraining_dbsubnet_group.name 
  vpc_security_group_ids = [ aws_security_group.tftraining_rds_sg.id ]
  skip_final_snapshot  = true
}

# creating target group attachment
resource "aws_lb_target_group_attachment" "tftraining_tg_attachment" {
  target_group_arn = aws_lb_target_group.tftraining_tg.arn
  target_id        = aws_instance.tftraining_ec2_server.id
  port             = 80
}






#creating application loadbalancer using terraform

resource "aws_lb" "tftraining_alb" {
  name               = "tftrainings-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tftraining_alb_sg.id]
  subnets            = [aws_subnet.tftraining_public_subnet1.id, aws_subnet.tftraining_public_subnet2.id]

  enable_deletion_protection = false

  #   access_logs {
  #     bucket  = aws_s3_bucket.lb_logs.id
  #     prefix  = "test-lb"
  #     enabled = true
  #   }

  tags = {
    Environment = "${var.environment}"
  }
}


#creating alb listener 

resource "aws_lb_listener" "tftraining_web" {
  load_balancer_arn = aws_lb.tftraining_alb.arn
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tftraining_tg.arn
  }
}

#creating target group
resource "aws_lb_target_group" "tftraining_tg" {
  name     = "tftraining-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.tftrainingvpc.id
}

#data for hosted zone


data "aws_route53_zone" "fetch_domain" {
  name         = var.domain_name
  private_zone = false
}



#creating zone id

resource "aws_route53_record" "tftraining_www" {
  zone_id = data.aws_route53_zone.fetch_domain.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.tftraining_alb.dns_name
    zone_id                = aws_lb.tftraining_alb.zone_id
    evaluate_target_health = true
  }
}

