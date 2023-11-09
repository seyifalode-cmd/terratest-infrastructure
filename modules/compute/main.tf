#-----compute/main.tf-----
#==========================
provider "aws" {
  region = var.region
}

#Get Linux AMI ID using SSM Parameter endpoint
#==============================================
data "aws_ssm_parameter" "webserver-ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

#Create key-pair for logging into EC2 
#======================================
resource "aws_key_pair" "aws-key" {
  key_name   = "webserver"
  public_key = file(var.ssh_key_public)
}

#Create and bootstrap webserver
#===================================
resource "aws_instance" "webserver" {
  instance_type               = "t2.micro"
  ami                         = data.aws_ssm_parameter.webserver-ami.value
  tags = {
    Name = "webserver_tf"
  }
  key_name                    = aws_key_pair.aws-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group]
  subnet_id                   = var.subnets
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo usermod -a -G apache ec2-user
              sudo chown -R ec2-user:apache /var/www
              sudo chmod 2775 /var/www
              sudo find /var/www -type d -exec chmod 2775 {} \;
              sudo find /var/www -type f -exec chmod 0664 {} \;
              sudo echo "<html><body><h1>Automated Terraform Testing</h1></body></html>" >> /var/www/html/index.html
              sudo service httpd start
              EOF

  connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh_key_private)
      host        = self.public_ip
  }
}