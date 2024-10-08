#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
nc="\033[0m"

usage() {
    echo -e "${yellow}usage: $0 <region> <alias>${nc}"
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

region="$1"
alias="$2"
bucket_name="tinstafl-$(echo "$alias" | tr '[:upper:]' '[:lower:]')"

check_success() {
    if [ $? -ne 0 ]; then
        echo -e "${red}$1${nc}"
        exit 1
    fi
}

echo -e "${yellow}creating s3 bucket: $bucket_name in region: $region${nc}"
aws s3api create-bucket --no-cli-pager --bucket "$bucket_name" --region "$region" --create-bucket-configuration LocationConstraint="$region"
check_success "failed to create s3 bucket: $bucket_name"

echo -e "${green}s3 bucket created successfully: $bucket_name${nc}"

echo -e "${yellow}setting object ownership to bucket_owner_enforced for $bucket_name${nc}"
aws s3api put-bucket-ownership-controls --bucket "$bucket_name" --ownership-controls "Rules=[{ObjectOwnership=BucketOwnerEnforced}]"
check_success "failed to set object ownership controls for bucket: $bucket_name"

echo -e "${green}object ownership set successfully for bucket: $bucket_name${nc}"

bucket_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "${alias}-ownership",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::$bucket_name",
                "arn:aws:s3:::$bucket_name/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOF
)

echo -e "${yellow}attaching bucket policy to $bucket_name${nc}"
aws s3api put-bucket-policy --bucket "$bucket_name" --policy "$bucket_policy"
check_success "failed to attach bucket policy for bucket: $bucket_name"

echo -e "${green}bucket policy attached successfully for bucket: $bucket_name${nc}"
