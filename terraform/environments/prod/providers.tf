# デフォルトリージョン
provider "aws" {
  profile = var.profile
  region = var.region

  default_tags {
    tags = {
      TfName = local.tf.name
      TfEnv  = local.tf.env
    }
  }
}

provider "aws" {
  profile = var.profile
  region = "us-east-1"
  alias  = "useast1"

  default_tags {
    tags = {
      TfName = local.tf.name
      TfEnv  = local.tf.env
    }
  }
}
