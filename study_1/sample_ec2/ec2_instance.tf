provider "aws" {
  // providerブロックでは、providerの指定を行う。今回はAWS
  version = "2.23.0"
  region = "ap-northeast-1"
}

// terraformブロック
// terraformの設定を書いていく。
// versionはいくつか？tsstateファイルをどこにおくか？など
terraform {
  required_version = "0.12.20"
  // backend argument... どこにtsstateファイルをおくかを指定。
  // 今回はs3
  backend "s3" {
    bucket = "terraform-sample-ec2-bucket"
    key    = "sample_ec2/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

// dataブロック
// 外部データを参照できる。
// 今回は、AWS: aws_instance - Terraform by HashiCorpのサンプルのものを使用しています。
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

// resource
// デプロイいsたいリソースを定義する。
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name = var.name
  }
  // resource_lifesycle
  // resourceブロックはlifecycl argumentを記述できる。
  // 削除を防いだりなど、リソースのライフサイクルを設定できる。
//  lifecycle {
//    // 削除の前にリソースを作成する
//    create_before_destroy = true
//    // 削除を防ぐ。
//    prevent_destroy = true
//  }
}