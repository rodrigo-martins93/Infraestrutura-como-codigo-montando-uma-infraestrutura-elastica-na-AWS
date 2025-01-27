module "aws-prod" {
  source = "../../infra"
  instance_type = "t2.micro"
  region = "us-west-2"
  key_name = "iac-prod-west-2.pem"
  public_key = "iac-prod-west-2.pub"
  ami = "ami-0b8c6b923777519db"
  security_group = "production"
  description_sg = "allow_all_acess_production"
  auto_scaling_group_name = "PROD"
  max_size = 10
  min_size = 1
  production = true
}


