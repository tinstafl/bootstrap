#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <external-id> <principal-arn>"
    exit 1
fi

ROLE_NAME="tinstafl-handshake-$2"

ACCOUNT="$1"
EXTERNAL_ID="$2"
PRINCIPAL_ARN="$3"

TRUST_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "$PRINCIPAL_ARN"
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

POLICY_DIR="./policy"

for POLICY_FILE in "$POLICY_DIR"/*.json; do
    if [ ! -f "$POLICY_FILE" ]; then
        echo "no policy files found in directory: $POLICY_DIR"
        continue
    fi

    IAM_POLICY=$(<"$POLICY_FILE")
    IAM_POLICY=${IAM_POLICY//\$ACCOUNT/$ACCOUNT}
    IAM_POLICY=${IAM_POLICY//\$REGION/$REGION}
    IAM_POLICY=${IAM_POLICY//\$EXTERNAL_ID/$EXTERNAL_ID}

    if [ -z "$IAM_POLICY" ]; then
        echo "policy document is empty for file: $POLICY_FILE"
        continue
    fi

    echo "$IAM_POLICY" | jq . > /dev/null
    if [ $? -ne 0 ]; then
        echo "invalid json in policy file: $POLICY_FILE"
        continue
    fi

    POLICY_NAME=$(basename "$POLICY_FILE" .json)

    aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" --policy-document "$IAM_POLICY" 2>error.log

    if [ $? -ne 0 ]; then
        echo "failed to attach policy: $POLICY_NAME to role: $ROLE_NAME"
        cat error.log
    else
        echo "successfully attached policy: $POLICY_NAME to role: $ROLE_NAME"
    fi
done
