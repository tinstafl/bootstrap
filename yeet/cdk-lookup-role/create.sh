#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <api-key> <alias>"
    exit 1
fi

role_name="tinstafl-lookup-$3"
account="$1"
external_id="$2"

trust_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$account:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "$external_id"
                }
            }
        }
    ]
}
EOF
)

if ! aws iam create-role --no-cli-pager --role-name "$role_name" --assume-role-policy-document "$trust_policy" 2>error.log; then
    echo "failed to create role: $role_name"
    exit 1
fi

if ! aws iam attach-role-policy --role-name "$role_name" --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess" 2>error.log; then
    echo "failed to attach ReadOnlyAccess policy to role: $role_name"
else
    echo "successfully attached ReadOnlyAccess policy to role: $role_name"
fi

no_decryption_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalAccount": "$account"
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

policy_name="no-decryption"

if ! aws iam put-role-policy --role-name "$role_name" --policy-name "$policy_name" --policy-document "$no_decryption_policy" 2>error.log; then
    echo "failed to attach policy: $policy_name to role: $role_name"
    cat error.log
else
    echo "successfully attached policy: $policy_name to role: $role_name"
fi
