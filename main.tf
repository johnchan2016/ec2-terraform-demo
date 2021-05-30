provider "aws" {
  region = "us-west-1"
}

## windows
# $ set AWS_ACCESS_KEY_ID="anaccesskey"
# $ set AWS_SECRET_ACCESS_KEY="asecretkey"
# $ set AWS_DEFAULT_REGION="us-west-2"


resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

module "myapp-subnet" {
  source                    = "./modules/subnet"
  subnet_cidr_block         = var.subnet_cidr_block
  private_subnet_cidr_block = var.private_subnet_cidr_block
  avail_zone                = var.avail_zone
  env_prefix                = var.env_prefix
  vpc_id                    = aws_vpc.myapp-vpc.id
  default_route_table_id    = aws_vpc.myapp-vpc.default_route_table_id
}

module "myapp-server" {
  source              = "./modules/webserver"
  vpc_id              = aws_vpc.myapp-vpc.id
  env_prefix          = var.env_prefix
  image_name          = var.image_name
  public_key_location = var.public_key_location
  instance_type       = var.instance_type
  subnet_id           = module.myapp-subnet.subnet.id
  avail_zone          = var.avail_zone
}

