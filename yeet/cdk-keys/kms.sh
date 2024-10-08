#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <account> <alias>"
    exit 1
fi

account="$1"
alias_name="alias/tinstafl-$2"
red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

log_success() {
    printf "%b%s%b\n" "$green" "$1" "$nc"
}

log_error() {
    printf "%berror: %s%b\n" "$red" "$1" "$nc"
}

echo "creating kms key for cdk toolchain..."
kms_key_id=$(aws kms create-key --description "kms key for cdk toolchain" \
    --key-usage ENCRYPT_DECRYPT \
    --origin AWS_KMS \
    --output text --query KeyMetadata.KeyId)

if [ -z "$kms_key_id" ]; then
    log_error "failed to create kms key"
    exit 1
fi

echo "enabling key rotation for kms key..."
if ! aws kms enable-key-rotation --key-id "$kms_key_id"; then
    log_error "failed to enable key rotation"
    exit 1
fi

echo "creating alias $alias_name for kms key..."
if ! aws kms create-alias --no-cli-pager --alias-name "$alias_name" --target-key-id "$kms_key_id"; then
    log_error "failed to create alias $alias_name"
    exit 1
fi

echo "attaching key policy for cdk and related services..."

key_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Id": "cdk-toolchain-key-policy",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cloudformation.amazonaws.com",
                    "codepipeline.amazonaws.com",
                    "codedeploy.amazonaws.com"
                ]
            },
            "Action": [
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$account:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOF
)

if ! aws kms put-key-policy --key-id "$kms_key_id" --policy-name "default" --policy "$key_policy"; then
    log_error "failed to attach key policy"
    exit 1
fi

kms_key_arn=$(aws kms describe-key --key-id "$kms_key_id" --output text --query KeyMetadata.Arn)

if [ -z "$kms_key_arn" ]; then
    log_error "failed to retrieve kms key arn"
    exit 1
fi

log_success "kms key created successfully. arn: $kms_key_arn"

key_id="${kms_key_arn##*:key/}"
log_success "key id: $key_id"
