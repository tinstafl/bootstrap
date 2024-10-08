#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "usage: $0 <account> <external-id>"
    exit 1
fi

ACCOUNT="$1"
ALIAS_NAME="alias/tinstafl-$2"

echo "creating kms key for cdk toolchain..."
KMS_KEY_ID=$(aws kms create-key --description "kms key for cdk toolchain" \
    --key-usage ENCRYPT_DECRYPT \
    --origin AWS_KMS \
    --output text --query KeyMetadata.KeyId)

if [ -z "$KMS_KEY_ID" ]; then
    echo "failed to create kms key"
    exit 1
fi

echo "enabling key rotation..."
aws kms enable-key-rotation --key-id "$KMS_KEY_ID"

echo "creating alias $ALIAS_NAME for kms key..."
aws kms create-alias --no-cli-pager --alias-name "$ALIAS_NAME" --target-key-id "$KMS_KEY_ID"

echo "attaching key policy for cdk and related services..."

KEY_POLICY=$(cat <<EOF
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
                "AWS": "arn:aws:iam::$ACCOUNT:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOF
)

aws kms put-key-policy --key-id "$KMS_KEY_ID" --policy-name "default" --policy "$KEY_POLICY"

KMS_KEY_ARN=$(aws kms describe-key --key-id "$KMS_KEY_ID" --output text --query KeyMetadata.Arn)

if [ -z "$KMS_KEY_ARN" ]; then
    echo "failed to retrieve kms key arn"
    exit 1
fi

echo "kms key created successfully. arn: $KMS_KEY_ARN"
