#!/bin/bash
yum update -y
yum install -y docker
docker run helloworld --log-driver=awslogs \
                      --log-opt awslogs-region=us-east-1 \
                      --log-opt awslogs-group=${group}