# If you don't set a default, then you will need to provide the variable
# at run time using the command line, or set it in the environment. For more
# information about the various options for setting variables, see the template
# [reference documentation](https://www.packer.io/docs/templates)
variable "profile" {
  type    = string
}

variable "ami_name" {
  type    = string
  default = "tooling"
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "instance_type" {
  type    = string
  default = "t4g.micro"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks configure your builder plugins; your source is then used inside
# build blocks to create resources. A build block runs provisioners and
# post-processors on an instance created by the source.
source "amazon-ebs" "latest_amazon_linux_2" {
  profile       = "${var.profile}"
  region        = "${var.region}"
  instance_type = "${var.instance_type}"
  ami_name      = "${var.ami_name} ${local.timestamp}"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-arm64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.latest_amazon_linux_2"]
  provisioner "shell" {
    script = "provision.sh"
  }
  provisioner "file"{
    source = ".ssh/id_ed25519"
    destination = "/home/ec2-user/.ssh/id_ed25519"
  }
}
