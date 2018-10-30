provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
	region = "us-east-1"
}

resource "aws_vpc" "vpc" {
	cidr_block = "10.0.0.0/16"
	tags {
	  Name = "scenario2"
	}
}

resource "aws_subnet" "public" {
	vpc_id =  "${aws_vpc.vpc.id}"
	cidr_block = "10.0.0.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "us-east-1b"

	tags {
		Name = "Public 1A"
	}
}

resource "aws_subnet" "private" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.1.0/24"
	availability_zone = "us-east-1b"

	tags {
		Name = "private"
	}
}

resource "aws_internet_gateway" "gateway" {
	vpc_id = "${aws_vpc.vpc.id}"

	tags {
		Name = "scenario2_gateway"
	}
}

resource "aws_route_table" "internet_route" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id =  "${aws_internet_gateway.gateway.id}"
  }
}

resource "aws_route_table_association" "one" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.internet_route.id}"
}



resource "aws_security_group" "helloworld" {
    name = "Hello World"
    description = "Hello World security group, doesn't really allow access to anything"
    vpc_id = "aws_vpc.vpc"
}



resource "aws_cloudwatch_log_group" "helloworld" {
    name = "hello_world_docker_logs"
    retention_in_days = "7"
    tags = {
        Environment = "production"
        Application = "Hello World"
    }

}

resource "aws_iam_instance_profile" "helloworld" {
    name = "helloworld_profile"
    role = "${aws_iam_role.role.helloworld}"
}

resource "aws_iam_role" "helloworld" {
    name = "helloworld_role"
    path = "/"
    assume_role_policy = <<EOF
{
    
}
EOF
}

data "template_file" "user_data" {
    template = "${file(user_data.tpl)}"
    vars {
        group = "${aws_cloudwatch_log_group.helloworld.name}"
    }
}

resource "aws_instance" "helloworld" {
    count = "${var.instance_count}"
    ami = "ami-0922553b7b0369273"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.public.id}"
    vpc_security_group_ids = ["${aws_security_group.helloworld}"]
    iam_instance_profile = "${aws_iam_instance_profile.helloworld}"
    user_data = "${data.template_file.user_data.rendered}"
    tags {
      Name = "${var.tag_name}"
    }
}