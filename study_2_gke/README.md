# TerraformでGKEクラスタを立ててみる。
Terraformを使ったクラウド構築第二弾です。
今回はGKEクラスタを構築してみます。

# 環境
MacOS
tfenv 1.0.2
Terraform v0.12.20
Google Cloud SDK 245.0.0

# 前提条件
- gcloudが自身のPCで使える
- terraformが自身のPCにインストールされている。

# Google Cloud SDK の設定

## Kubernetes Engine APIを有効にする
以下のコマンドを実行して、container APIを操作できるようにする。
```shell script
gcloud services enable container.googleapis.com
```

## Terraformのサービスアカウントを作成する
## 現在のプロジェクトの確認
まずは、cloudのconfig情報を出力し、現在接続されているプロジェクト情報などを確認しておく。
```shell script
gcloud config configurations list

NAME     IS_ACTIVE  ACCOUNT             PROJECT  DEFAULT_ZONE       DEFAULT_REGION
default  True       *******             *******   asia-northeast1-a
```

### Tips プロジェクトを切り替えたいのであれば...
`config set`でプロジェクトを切り替えられる。

```shell script
# 自分のプロジェクト一覧を出力
gcloud projects list

# プロジェクトの切り替え
gcloud config set project <PROJECT_ID>
```


## 環境変数を用意
後の手順が楽なように、環境変数を設定していく。

```shell script
# GCPのプロジェクトID
GCP_PROJECT=$(gcloud info --format='value(config.project)')
# Terraformのサービスアカウント名
TERRAFORM_SA=terraform-service-account

#GCSのクラス 
GCS_CLASS=multi_regional
#GCSのバケット名
GCS_BUCKET=~~tf-sample-backet~~
```

## gcloudで使用するTerraformのサービスアカウントを作成する
```shell script
gcloud iam service-accounts create $TERRAFORM_SA --project=$GCP_PROJECT --display-name $TERRAFORM_SA
```

## 作成したTerraformアカウントに、権限を付与する。
付与したい権限は、

- roles/iam.serviceAccountUser
-- Compute Engine IAM の役割
- roles/compute.admin
- roles/storage.admin
- roles/container.clusterAdmin


```shell script

```

```shell script
# 使い回しがきくように、Terraformのサービスアカウントのメールアドレスを環境変数に設定。
TERRAFORM_SA_EMAIL=$(gcloud iam service-accounts list --project=$GCP_PROJECT --filter="displayName:$TERRAFORM_SA" --format='value(email)')
# 権限の付与
gcloud projects add-iam-policy-binding $GCP_PROJECT --role roles/iam.serviceAccountUser --member serviceAccount:$TERRAFORM_SA_EMAIL
gcloud projects add-iam-policy-binding $GCP_PROJECT --role roles/compute.admin --member serviceAccount:$TERRAFORM_SA_EMAIL
gcloud projects add-iam-policy-binding $GCP_PROJECT --role roles/storage.admin --member serviceAccount:$TERRAFORM_SA_EMAIL
gcloud projects add-iam-policy-binding $GCP_PROJECT --role roles/container.clusterAdmin --member serviceAccount:$TERRAFORM_SA_EMAIL
```

# .tfstateファイルを管理するGoogle Cloud Storageバケットを作成する。
Terraformでは管理しているリソース状態を`.tfstate`という拡張子をもつファイルで管理する。  
ローカルでも保存されるが、共有できないためそのファイルをリモートで管理する。  
その置き場としての、GCバケットを作成する。
  
以下のコマンドを実行するとGCSが作成される。
```shell script
gsutil mb -p $GCP_PROJECT -c $GCS_CLASS -l asia gs://$GCS_BUCKET/
```

※gsutilコマンドは、GCSを操作するためのコマンドラインツール。  
Google Cloud SDKをインストールする大mングで利用できるようになる。

### GCSバケットが作成されたかを確認
```shell script
gsutil ls
```


以下のように出力されればOK
```
gs://tf-sample-backet/
```

# .tsファイルを作成する。
作成する


# GKEの作成
用意したtsファイルを使用して、GKEを作成する。

## Terraformのサービスアカウントのjsonファイルを作成する。
```shell script
TERRAFORM_SA_DEST=.gcp/terraform-service-account.json

mkdir -p $(dirname $TERRAFORM_SA_DEST)

TERRAFORM_SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:$TERRAFORM_SA" --format='value(email)')

gcloud iam service-accounts keys create $TERRAFORM_SA_DEST --iam-account $TERRAFORM_SA_EMAIL
```
