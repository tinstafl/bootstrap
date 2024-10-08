# bootstrap

## yeet

creates roles for a new subscriber to allow cross account access for feature system deployments

```shell
bash --version
GNU bash, version 5.2.26(1)-release (aarch64-apple-darwin23.2.0)

zsh --version
zsh 5.9 (x86_64-apple-darwin23.0)

aws --version
aws-cli/2.15.53 Python/3.11.8 Darwin/23.6.0 exe/x86_64

jq --version
jq-1.7.1

cd yeet

# create all resources
./create.sh <aws-account-id> <region> <api-key> <subscriber-role>

# delete all resources
./delete.sh <api-key> <kms-key-id>
```

## saasy

soon.
