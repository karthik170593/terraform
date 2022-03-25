provider "aws" {
    region = "ap-south-1"
    access_key = "AKIAV7VCXJBU3ZY5FR23"
    secret_key = "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"
}
    resource "aws_key_pair" "my_instance_key_pair" {
    key_name = "test_public_key"
    public_key = file("id_rsa.pub")
}

resource "aws_instance" "my_instance" {
    ami = "ami-04893cdb768d0f9ee"
    instance_type = "t2.micro"
    user_data = "${file("install_nodejs.sh")}"
    count = 2
    key_name = aws_key_pair.my_instance_key_pair.key_name
    vpc_security_group_ids = [aws_security_group.my_vpc_security_group.id]
    subnet_id = aws_subnet.my_public_subnet.id
    associate_public_ip_address = true
}

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
}

resource "aws_security_group" "my_vpc_security_group" {  
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_subnet" "my_public_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "my_internet_gateway" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_public_route_table" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_internet_gateway.id
    }
}

resource "aws_route_table_association" "my_public_route_table_association" {
  subnet_id = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_public_route_table.id
}

output "public-dns" {
    value = aws_instance.my_instance.*.public_dns[0]
}
output "public-ip" {
    value = aws_instance.my_instance.*.public_ip[0]
}

