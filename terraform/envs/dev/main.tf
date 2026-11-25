data "aws_caller_identity" "current" {}
data "aws_vpc" "default" {
  default = true
}

# One subnet in AZ "a" (some instance types are missing in us-east-1e)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["${var.region}a"]
  }
}

module "lab_server" {
  source     = "../../modules/lab-server"
  name       = "${var.project}-lab"
  vpc_id     = data.aws_vpc.default.id
  subnet_id  = data.aws_subnets.default.ids[0]
  ssh_cidr   = var.my_ip_cidr
  public_key = file(pathexpand(var.ssh_public_key_path))
}
