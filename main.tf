terraform {
    required_version = "~> 0.11.10"
}

provider "template" {
    version = "~> 1.0"
}

provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
	region = "us-east-1"
    version = "~> 1.41"
}

#### Variables
variable "access_key" {
    type = "string"
}
variable "secret_key" {
    type = "string"
}
variable "instance_count" {
    type = "string"
    default = "2"
}

#### VPC
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

#### Security Groups
resource "aws_security_group" "helloworld" {
    name = "Hello World"
    description = "Hello World security group"
    vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group_rule" "egress_all" {
    from_port = 0
    to_port = 65535
    protocol = -1
    type = "egress"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.helloworld.id}"
}

#### CloudWatch Logs
resource "aws_cloudwatch_log_group" "helloworld" {
    name = "hello_world_docker_logs"
    retention_in_days = "7"
    tags = {
        Environment = "production"
        Application = "Hello World"
    }

}

#### IAM
resource "aws_iam_instance_profile" "helloworld" {
    name = "helloworld_profile"
    role = "${aws_iam_role.helloworld.name}"
}

resource "aws_iam_policy" "helloworld" {
    name = "helloworld_policy"
    path = "/"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudWatchLogsDockerHelloWorld",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:882214212742:log-group:hello_world_docker_logs",
                "arn:aws:logs:us-east-1:882214212742:log-group:hello_world_docker_logs:*:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "helloworld" {
    name = "helloworld_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "helloworld" {
    role = "${aws_iam_role.helloworld.name}"
    policy_arn = "${aws_iam_policy.helloworld.arn}"
}

#### Instance
data "template_file" "user_data" {
    template = "${file("user_data.sh.tpl")}"
    vars {
        group = "${aws_cloudwatch_log_group.helloworld.name}"
    }
}

resource "aws_instance" "helloworld" {
    count = "${var.instance_count}"
    ami = "ami-0922553b7b0369273"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.public.id}"
    vpc_security_group_ids = ["${aws_security_group.helloworld.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.helloworld.name}"
    user_data = "${data.template_file.user_data.rendered}"
    associate_public_ip_address = true
    tags {
      Name = "helloworld-${count.index}"
    }
}

#### Output

output "Open CloudWatch and wait/refresh to see results:" {
    value = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logStream:group=hello_world_docker_logs"
}