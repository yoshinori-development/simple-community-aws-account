## プロファイル指定
export AWS_PROFILE="community"

## コマンド
```
terraform fmt -recursive
```

```
./prepare-tfstate.sh
```

```
terraform init
```

```
terraform plan
```

```
terraform apply
```


## プロバイダの更新時
```
terraform init -upgrade
```