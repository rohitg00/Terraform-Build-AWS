//Describing Provider
provider "aws" {
  region  = "ap-south-1"
  profile = "rg"
}

//Creating Variable for AMI_ID
variable "ami_id" {
  type    = string
  default = "ami-0447a12f28fddb066"
}

//Creating Variable for AMI_Type
variable "ami_type" {
  type    = string
  default = "t2.micro"
}

//Creating Key
resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
}

//Generating Key-Value Pair
resource "aws_key_pair" "generated_key" {
  key_name   = "rg-env-key"
  public_key = "${tls_private_key.tls_key.public_key_openssh}"

  depends_on = [
    tls_private_key.tls_key
  ]
}

//Saving Private Key PEM File
resource "local_file" "key-file" {
  content  = "${tls_private_key.tls_key.private_key_pem}"
  filename = "rg-env-key.pem"

  depends_on = [
    tls_private_key.tls_key
  ]
}

//Creating Security Group
resource "aws_security_group" "web-SG" {
  name        = "web-env-SG"
  description = "Web Environment Security Group"

  //Adding Rules to Security Group 
  ingress {
    description = "SSH Rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Rule"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//Creating a S3 Bucket
resource "aws_s3_bucket" "web-bucket" {
  bucket = "web-static-data-bucket"
  acl    = "public-read"
}

//Putting Objects in S3 Bucket
resource "aws_s3_bucket_object" "web-object1" {
  bucket = "${aws_s3_bucket.web-bucket.bucket}"
  key    = "ias1.png"
  source = "ias1.png"
  acl    = "public-read"
}

//Putting Objects in S3 Bucket
resource "aws_s3_bucket_object" "web-object2" {
  bucket = "${aws_s3_bucket.web-bucket.bucket}"
  key    = "ias2.png"
  source = "ias2.png"
  acl    = "public-read"
}

//Putting Objects in S3 Bucket
resource "aws_s3_bucket_object" "web-object3" {
  bucket = "${aws_s3_bucket.web-bucket.bucket}"
  key    = "ias3.png"
  source = "ias3.png"
  acl    = "public-read"
}

//Creating CloutFront with S3 Bucket Origin
resource "aws_cloudfront_distribution" "s3-web-distribution" {
  origin {
    domain_name = "${aws_s3_bucket.web-bucket.bucket_regional_domain_name}"
    origin_id   = "${aws_s3_bucket.web-bucket.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "S3 Web Distribution"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.web-bucket.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN"]
    }
  }

  tags = {
    Name        = "Web-CF-Distribution"
    Environment = "Production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [
    aws_s3_bucket.web-bucket
  ]
}

//Launching EC2 Instance
resource "aws_instance" "web" {
  ami             = "${var.ami_id}"
  instance_type   = "${var.ami_type}"
  key_name        = "${aws_key_pair.generated_key.key_name}"
  security_groups = ["${aws_security_group.web-SG.name}","default"]

  //Labelling the Instance
  tags = {
    Name = "Web-Env"
    env  = "Production"
  }

  //Put CloudFront URLs in our Website Code
  provisioner "local-exec" {
    command = "sed -i 's/CF_URL_Here/${aws_cloudfront_distribution.s3-web-distribution.domain_name}/g' webapp.html"
  }
  
  //Copy our Wesite Code i.e. HTML File in Instance
  provisioner "file" {
    connection {
      agent       = false
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${tls_private_key.tls_key.private_key_pem}"
      host        = "${aws_instance.web.public_ip}"
    }

    source      = "webapp.html"
    destination = "/home/ec2-user/webapp.html" 
  }


  //Executing Commands to initiate WebServer in Instance Over SSH 
  provisioner "remote-exec" {
    connection {
      agent       = "false"
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${tls_private_key.tls_key.private_key_pem}"
      host        = "${aws_instance.web.public_ip}"
    }
    
    inline = [
      "sudo yum install httpd -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
    ]

  }

  //Storing Key and IP in Local Files
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.public_ip} > public-ip.txt"
  }

  depends_on = [
    aws_security_group.web-SG,
    aws_key_pair.generated_key
  ]
}

//Creating EBS Volume
resource "aws_ebs_volume" "web-vol" {
  availability_zone = "${aws_instance.web.availability_zone}"
  size              = 1
  
  tags = {
    Name = "ebs-vol"
  }
}

//Attaching EBS Volume to a Instance
resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdh"
  volume_id    = "${aws_ebs_volume.web-vol.id}"
  instance_id  = "${aws_instance.web.id}"
  force_detach = true
  
  //Format and Mount EBS Volume then Copy our WebSite Code in Webserver Document Root
  provisioner "remote-exec" {
    connection {
      agent       = "false"
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${tls_private_key.tls_key.private_key_pem}"
      host        = "${aws_instance.web.public_ip}"
    }
    
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html/",
      "sudo cp /home/ec2-user/webapp.html /var/www/html/"
    ]
  }

  depends_on = [
    aws_instance.web,
    aws_ebs_volume.web-vol
  ]
}

//Creating EBS Snapshot
resource "aws_ebs_snapshot" "ebs_snapshot" {
  volume_id   = "${aws_ebs_volume.web-vol.id}"
  description = "Snapshot of our EBS volume"
  
  tags = {
    env = "Production"
  }

  depends_on = [
    aws_volume_attachment.ebs_att
  ]
}
