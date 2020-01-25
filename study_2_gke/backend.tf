terraform {
  backend "gcs" {
    bucket = "tf-sample-backet"
    prefix = "terraform/state"
  }
}