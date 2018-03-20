provider "aws" {
  region     = "us-west-2"
}

resource "aws_instance" "couchdb-staging" {
    ami                         = "ami-efd0428f"
    availability_zone           = "us-west-2a"
    ebs_optimized               = false
    instance_type               = "m3.medium"
    monitoring                  = false
    key_name                    = "key-name"
    subnet_id                   = "subnet-id"
    vpc_security_group_ids      = ["sg-id"]
    associate_public_ip_address = false

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 64
        delete_on_termination = false
    }

    tags {
        "Name" = "couchdb-staging"
        "Allocation" = "staging"
    }
    
    provisioner "file" {
      source      = "couchdb-install-singlenode.sh"
      destination = "/root/couchdb-install-singlenode.sh"
    }
    
    provisioner "remote-exec" {
      inline = [
        "chmod +x /root/couchdb-install-singlenode.sh",
        "/root/couchdb-install-singlenode.sh",
      ]
    }
}
