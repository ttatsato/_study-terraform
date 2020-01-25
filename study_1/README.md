# TerraformのEC2を立ち上げてみた

Terraformを使ってEC2を立ち上げてみた。

# 環境・前提条件
- Mac OS
- brewコマンドが使える。
- AWSアカウント発行済み
- AWS IAMにてユーザーを追加済み

# GOAL
- tfenvを使った方法でterraformを自身のMacにインストール
- terraformの構成ファイルの形式を理解する。
- terraformを使用して、AWSにEC2インスタンスを構築する。

# インストール
さっそく自身のPCにterraformをインストールする。
Terraformをインストールする前に、
## tfenvのインストール

### tfenvとは？

tfenvとは、rbenv,pyenvのようなTerraformのバージョンを管理するツール。
複数環境でそれぞれ別のTerraformのバージョンを使う際に便利。

### tfenvのインストールコマンド

```shell script
brew install tfenv
```

### tfenvがインストールされたかを確認
```shell script
tfenv --version
```
以下のように正常にバージョンが取得できれば、OK。

```shell script
tfenv 1.0.2

```

## tfenvを使ってterraformをインストール

### インストール可能なterraformのversionを確認する

```shell script
tfenv list-remote
```

とコマンどを実行すると以下のようにインストールできるversionが出力される。

```shell script
0.12.20
0.12.19
0.12.18
.....
```

### terrafromをバージョン指定してインストール

```shell script
tfenv install 0.12.20
```

#### インストールできたかを確認
```shell script
terraform --version                   
```
とコマンド実行。以下のように出力されればOK

``` shell script
Terraform v0.12.20
```

### (tips) tfenvのコマンド

```shell script
# インストールできるterraformの確認
tfenv list-remote

# インストール
tfenv install <terraform version>

# PCにインストール済みのversion一覧を出力
tfenv list

# 使用するversionの切り替え
tfenv use <version>
```

### ファイル .terraform-versionを作成する
チーム開発のとき、バージョンを明確に共有しておく必要がある。  
その際、.terraform-versionを作成して共有すれば、`tfenv install`の際にversion指定をしなくていい。
  ヒューマンエラーによるversion間違いを防げる。
```shell script
echo 0.12.20 > .terraform-version
```

# Terraformの構成言語を理解する。

# 構成言語の目的
Terraform言語のの主な目的は、リソースを宣言すること。 

## Terraformにおけるリソースとは 
ここで言う、リソースはAWSのEC2などの仮想ネットワーク、コンピューティングインスタンスなどのインフラストラクチャオブジェクトを指す。
## Terraformにおけるモジュールとは 
リソースのグループは、モジュールと呼ばれ、大きな構成単位として捉えられる。

## 記述するために、Terraform構成ファイルを用意する。
terraformでインフラの記述を行うためには、専用の構成ファイルを用意する。  
言語はTerraform言語。ファイルの拡張子は`.tf`
※ JSONファイルでも構成ファイルを用意することができる。ただし、推奨は専用形式。

# TerraformでAWS EC2を立てる
ファイルをいくつか用いて行うので、  
以下のようなディレクトリ/ファイルを作成する。

## tfstateファイルの置き場用のS3を作成しておく。
AWSコンソールからS3を立ち上げておく。

| | |
| ---- | ---- |
| bucket name | terraform-sample-ec2-bucket  |
| region | ap-northeast-1 |
```
$ tree
.
└── sample_ec2
    ├── ec2_instance.tf
    ├── outputs.tf
    └── variables.tf

```

#### ファイル作成用コマンド
```shell script
touch ec2_instance.tf
touch outputs.tf
touch variables.tf
```

## 作成した3つのファイルの目的。

- ec2_instance.tf
-- リソースの定義やProviderなどの設定をファイルで定義する
- outputs.tf
-- terraform apply時にコンソールに出力される。
-- 他のコンポーネントから参照させたいリソースの値を記述する。
- variables.tf
-- ec2_instance.tfで使用する変数を定義する。

## ec2_instance.tfを記述する
リソースやproviderの設定を定義するec2_instance.tfを記述していきます。

```hcl-terraform
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
```
※ `var.instance_type`などはvariables.tfで定義した変数を使う(後述)

## outputs.tfを記述する。
`terraform apply`実行時に出力されるファイルoutputs.tfを記述する。
```hcl-terraform
output "sample_ec2" {
  // ec2_instance.tfで定義したresourceのwebを出力する
  value = aws_instance.web
}
```

## variable.tfを記述する
ec2_instance.tfで使用する変数の値を定義する。

```hcl-terraform
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
```

## terraform init でTerraformを使う準備をする
sample_ec2ディレクトリに移動して実行する。
```shell script
# ~/sample_ec2

terraform init
```

### コマンド実行をするとエラーが出力される
```shell script
Initializing the backend...

Error: No valid credential sources found for AWS Provider.
        Please see https://terraform.io/docs/providers/aws/index.html for more information on
        providing credentials for the AWS Provider

```

要するにAWSのクレデンシャルが設定されていないのに、
providerにAWSが指定されているから怒られている。

## terraformで使用するAWSのクレデンシャルを設定する。
### aws-cliをinstallする

```shell script
pip3 install awscli --upgrade
```
以下のコマンドが正常に動作すればOK

```shell script
aws --version

# 例) 
# aws-cli/1.17.9 Python/3.7.0 Darwin/19.2.0 botocore/1.14.9
```

## terraformで使用するクレデンシャルを設定する
AWSのIAMを閲覧して、terraform用にクレデンシャルを設定する。
```shell script
export AWS_ACCESS_KEY_ID=${YOUR_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${YOUR_SECRET_ACCESS_KEY}
export AWS_DEFAULT_REGION=ap-northeast-1
```

## クレデンシャルを設定したので、再度 terraform init
```shell script
terraform init
```

以下のように表示され、`.teffaform`ディレクトリが生成されればOK

```shell script
Terraform has been successfully initialized!

```

### tips コード整形
```shell script
terraform fmt -recursive -check=true
```


## terraform planを実行して、デプロイ予定のリソースの詳細を確認する。
```shell script
terraform plan
```


以下のように出力されればOK
```shell script
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.aws_ami.ubuntu: Refreshing state...

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

.....

"terraform apply" is subsequently run.
```


## terraform apply で実際にEC2を立ててみる
```shell script
terraform apply
```

### 結果の確認
以下のように、outputs.tfで設定した値が出力されればOK

```shell script
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

sample_ec2 = {
  "associate_public_ip_address" = true
  "availability_zone" = "ap-northeast-1a"
  "cpu_core_count" = 1

.....
```

#### EC2のコンソール画面を開いてみる。
以下のURLにアクセスして本当にEC2インスタンスが作成されて、立ち上がっているか確かめる。

https://ap-northeast-1.console.aws.amazon.com/ec2/v2/home?region=ap-northeast-1#Instances:sort=instanceId
一覧に「HelloWorld」というNameのインスタンスがあればOK


#### terraform stateでインスタンスが立ち上がっているか確認

```shell script
terraform state pull
```

### tips applyの際のログを出力
環境変数「TF_LOG」を使うとログをファイル出力できる。
(ログレベルは、TRACE・DEBUG・INFO・WARN・ERROR)

```shell script
TF_LOG=debug terraform apply
```

# 立ち上げたEC2を削除する
```shell script
terraform destroy
```

#### 結果の確認 ~ 削除されたかどうか
以下のコマンドを実行して、`resources`が空ならOK。
```shell script
terraform state pull
```



