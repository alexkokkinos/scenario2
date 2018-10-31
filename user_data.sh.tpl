#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker.service
docker run --log-driver=awslogs --log-opt awslogs-region=us-east-1 --log-opt awslogs-group=${group} hello-world