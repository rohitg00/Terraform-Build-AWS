# Terraform-Build-AWS
Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions. Configuration files describe to Terraform the components needed to run a single application or your entire datacenter. Terraform generates an execution plan describing what it will do to reach the desired state, and then executes it to build the described infrastructure. The infrastructure Terraform can manage includes low-level components such as compute instances, storage, and networking, as well as high-level components such as DNS entries, SaaS features, etc

# Problem Statement:
## Create the private key and security group which allows the port 80.
## Launch Amazon AWS EC2 instance.
## In this EC2 instance use the key and security group which we have created in step 1 to log-in remote or local.
## Launch one Volume (EBS) and mount that volume into /var/www/html
## The developer has uploaded the code into GitHub repo also the repo has some images.
## Copy the GitHub repo code into /var/www/html
## Create an S3 bucket, and copy/deploy the images from GitHub repo into the s3 bucket and change the permission to public readable.
## Create a Cloudfront using S3 bucket(which contains images) and use the Cloudfront URL to update in code in /var/www/html
# Optional:
## Those who are familiar with Jenkins or are in DevOps AL have to integrate Jenkins in this task wherever you feel can be integrated.
## Create a snapshot of EBS.

# Blog
[BLog for Terraform Cloud Automation](https://medium.com/@ghumare64/terraform-is-a-secret-towards-cloud-automation-%EF%B8%8F-f9c9463b0304)

# Author
[Rohit Ghumare](https://github.com/rohitg00)
