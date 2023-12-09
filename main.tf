terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "event_bridge" {
  source = "./modules/eventbridge"
  event_pattern = var.event_pattern
}