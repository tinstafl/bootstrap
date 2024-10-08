#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <account> <external-id>"
    exit 1
fi

ROLE_NAME="tinstafl-lookup-$2"

ACCOUNT="$1"
EXTERNAL_ID="$2"

TRUST_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$ACCOUNT:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "$EXTERNAL_ID"
                }
            }
      }
    ]
}
EOF
)

aws iam create-role --no-cli-pager --role-name "$ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY" 2>error.log

if [ $? -ne 0 ]; then
    echo "failed to create role: $ROLE_NAME"
    exit 1
fi

aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess" 2>error.log

if [ $? -ne 0 ]; then
    echo "failed to attach ReadOnlyAccess policy to role: $ROLE_NAME"
else
    echo "successfully attached ReadOnlyAccess policy to role: $ROLE_NAME"
fi

NO_DECRYPTION_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalAccount": "$ACCOUNT"
                }
            },
            "Action": "kms:Decrypt",
            "Resource": "*",
            "Effect": "Deny"
        }
    ]
}
EOF
)

POLICY_NAME="no-decryption"

aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" --policy-document "$NO_DECRYPTION_POLICY" 2>error.log

if [ $? -ne 0 ]; then
    echo "failed to attach policy: $POLICY_NAME to role: $ROLE_NAME"
    cat error.log
else
    echo "successfully attached policy: $POLICY_NAME to role: $ROLE_NAME"
fi
