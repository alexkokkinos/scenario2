# scenario2
Scenario 2 VPC saying Hello World with Terraform

## Purpose

This project uses Terraform to build a Scenario 2 VPC, launch a number of instances, and start the Hello World docker container on each desired EC2 Instance.

### AWS Account Charges Ahead!

By following the instructions below, you will create t2.micro instances, a VPC, and other AWS infrastructure. Get your wallet out!

## How to use

1. Ensure your AWS IAM user has rights to create VPCs, Security Groups, IAM users/roles, CloudWatch Logs, and EC2 Instances.
1. Ensure Terraform 0.11.10 is installed
1. Clone this repository's master branch
1. In the root directory of this repository, create `terraform.tfvars` and populate it with the following information:

    ``` ini
    access_key = "your_iam_access_key"
    secret_key = "your_iam_secret_key"
    ```

1. Run the following command in the bash shell. **You will not be prompted if you include the `-auto-approve` flag**:

    ``` bash
    terraform init && terraform apply -auto-approve
    ```

    The above will default to creating two EC2 Instances running the Hello World container. To specify a quantity, run the following:

    ``` bash
    terraform init && terraform apply -auto-approve -var 'instance_count=#'
    ```

    where `#` is an integer representing the number of desired instances.

    If you wish to run all of the above at once, you may run the following with the variable values substituted (polluting your history with your AWS IAM credentials):

    ``` bash
    terraform init && terraform apply -auto-approve -var 'instance_count=#' -var 'access_key=your_iam_access_key' -var 'secret_key=your_iam_secret_key'
    ```

1. At the end of the Terraform run, the EC2 instances will be created, and they'll start the hello-world Docker container. The instances will automatically output their results to CloudWatch. Please give the instances a few seconds to run the container before [viewing the results](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logStream:group=hello_world_docker_logs). When clicking this link, you may be prompted to login to your AWS console if you are not logged in already (but this link is the direct link to where you need to be). 

After running `terraform init` once, you do not need to run it again.

This exercise stipulates a requirement to run all actions in one command. The above instructions run two commands on one shell line, and, depending on your interpretation, that could be considered a violation of the exercise. I decided against providing a single script reimplementing the commands and arguments because in a real production environment, it would be assumed that the engineer would have already run `terraform init`, and that script would add unnecessary complexity.

## Destroying the Infrastructure

When you're done, simply run `terraform destroy` to revert everything.

## Considerations

While working on this exercise, I made decisions that would diverge from a real production environment:

- These instances are never given a key pair, so there is no way to SSH to them. Using the Docker [awslogs](https://docs.docker.com/config/containers/logging/awslogs/) was the best fit for performing basic verification that the containers started.
- All of the Terraform code is contained in main.tf to keep the exercise straightforward. Normally, repeatable pieces of infrastructure would be broken up into modules.
- This project uses local state files, which would not be acceptable in a production environment. [A different backend](https://www.terraform.io/docs/backends/types/index.html) would provide locking, consistency checking, and more robust state recovery
- If the `user_data` script became any more complex, I would have used a configuration management tool instead.