module "aws-dev" {
  source = "../../infra"
  instance_type = "t2.micro"
  region = "us-east-1"
  key_name = "iac-pem-useast-1.pem"
  public_key = "iac-pem-useast-1.pub"
  ami = "ami-0e2c8caa4b6378d8c"
  security_group = "dev"
  description_sg = "allow_all_acess_dev"
  auto_scaling_group_name = "DEV"
  max_size = 1
  min_size = 1
  production = false
}

