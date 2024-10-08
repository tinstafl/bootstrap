#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <region> <external-id>"
    exit 1
fi

REGION="$1"
EXTERNAL_ID="$2"
BUCKET_NAME="tinstafl-$(echo "$EXTERNAL_ID" | tr '[:upper:]' '[:lower:]')"

check_success() {
    if [ $? -ne 0 ]; then
        echo "$1"
        exit 1
    fi
}

echo "creating s3 bucket: $BUCKET_NAME in region: $REGION"
aws s3api create-bucket --no-cli-pager --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
check_success "failed to create s3 bucket: $BUCKET_NAME"

echo "s3 bucket created successfully: $BUCKET_NAME"

echo "setting object ownership to bucket_owner_enforced"
aws s3api put-bucket-ownership-controls --bucket "$BUCKET_NAME" --ownership-controls "Rules=[{ObjectOwnership=BucketOwnerEnforced}]"
check_success "failed to set object ownership controls for bucket: $BUCKET_NAME"

BUCKET_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "'"$EXTERNAL_ID"'-ownership",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::'"$BUCKET_NAME"'",
                "arn:aws:s3:::'"$BUCKET_NAME"'/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}'

echo "attaching bucket policy to $BUCKET_NAME"
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "$BUCKET_POLICY"
check_success "failed to attach bucket policy for bucket: $BUCKET_NAME"

echo "bucket policy attached successfully."

echo "lifecycle rules set successfully for bucket: $BUCKET_NAME"
