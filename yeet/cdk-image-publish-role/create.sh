#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <region> <external-id>"
    exit 1
fi

ROLE_NAME="tinstafl-images-$3"
POLICY_DIR="./policy"

ACCOUNT="$1"
REGION="$2"
EXTERNAL_ID="$3"

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

if [ ! -d "$POLICY_DIR" ]; then
    echo "policy directory not found: $POLICY_DIR"
    exit 1
fi

attach_policy() {
    local policy_file="$1"
    local role_name="$2"
    local account="$3"
    local region="$4"
    local external_id="$5"

    if [ ! -f "$policy_file" ]; then
        echo "policy file not found: $policy_file"
        return
    fi

    IAM_POLICY=$(<"$policy_file")
    IAM_POLICY=${IAM_POLICY//\$ACCOUNT/$account}
    IAM_POLICY=${IAM_POLICY//\$REGION/$region}
    IAM_POLICY=${IAM_POLICY//\$EXTERNAL_ID/$external_id}

    if [ -z "$IAM_POLICY" ]; then
        echo "policy document is empty for file: $policy_file"
        return
    fi

    echo "$IAM_POLICY" | jq . > /dev/null
    if [ $? -ne 0 ]; then
        echo "invalid json in policy file: $policy_file"
        return
    fi

    POLICY_NAME=$(basename "$policy_file" .json)

    aws iam put-role-policy --role-name "$role_name" --policy-name "$POLICY_NAME" --policy-document "$IAM_POLICY" 2>error.log

    if [ $? -ne 0 ]; then
        echo "failed to attach policy: $POLICY_NAME to role: $role_name"
        cat error.log
    else
        echo "successfully attached policy: $POLICY_NAME to role: $role_name"
    fi
}

attach_policy "./policy/ecr.json" "$ROLE_NAME" "$ACCOUNT" "$REGION" "$(echo "$EXTERNAL_ID" | tr '[:upper:]' '[:lower:]')"
