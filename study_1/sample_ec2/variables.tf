variable "name" {
  // 変数の説明
  description = "ec2のインスタンスの名前"
  type = string
  default = "HelloWord"
}

variable "instance_type" {
  description = "sample_ec2mのインスタンスタイプ"
  type = string
  default = "t2.micro"
}