#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <region> <external-id>"
    exit 1
fi

ACCOUNT="$1"
REGION="$2"
EXTERNAL_ID="$3"

REPOSITORY_NAME="tinstafl-$(echo "$EXTERNAL_ID" | tr '[:upper:]' '[:lower:]')"

echo "creating ecr repository: $REPOSITORY_NAME"
CREATE_OUTPUT=$(aws ecr create-repository --repository-name "$REPOSITORY_NAME" --region "$REGION" --no-cli-pager 2>&1)
if [ $? -ne 0 ]; then
    echo "failed to create ecr repository: $CREATE_OUTPUT"
    exit 1
fi

POLICY_DOCUMENT='{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Principal": { "AWS": "arn:aws:iam::'$ACCOUNT':role/tinstafl-exec-'$EXTERNAL_ID'" }, "Action": [ "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:DescribeRepositories" ] } ] }'

echo "$POLICY_DOCUMENT"

echo "$POLICY_DOCUMENT" | jq . >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "invalid json policy document."
    exit 1
fi

echo "Attaching policy to ECR repository: $REPOSITORY_NAME"
SET_POLICY_OUTPUT=$(aws ecr set-repository-policy --repository-name "$REPOSITORY_NAME" --policy-text "$POLICY_DOCUMENT" --region "$REGION" 2>&1)
if [ $? -ne 0 ]; then
    echo "failed to attach policy to ecr repository: $SET_POLICY_OUTPUT"
    exit 1
fi

echo "successfully attached policy to ecr repository: $REPOSITORY_NAME"
