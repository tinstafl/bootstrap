#!/bin/bash

if [ "$#" -lt 4 ]; then
    echo "usage: $0 <account> <region> <external-id> <version>"
    exit 1
fi

ACCOUNT="$1"
REGION="$2"
EXTERNAL_ID="$3"
VERSION="$4"

PARAMETER_NAME="/cdk/tinstafl-$EXTERNAL_ID/version"
PARAMETER_VALUE="$VERSION"

echo "creating ssm parameter: $PARAMETER_NAME in region: $REGION"

aws ssm put-parameter --no-cli-pager --name "$PARAMETER_NAME" \
    --value "$PARAMETER_VALUE" \
    --type "String" \
    --region "$REGION" \
    --overwrite

if [ $? -ne 0 ]; then
    echo "failed to create ssm parameter"
    exit 1
fi

PARAMETER_ARN="arn:aws:ssm:$REGION:$ACCOUNT:parameter$PARAMETER_NAME"

echo "ssm parameter created successfully. arn: $PARAMETER_ARN"
