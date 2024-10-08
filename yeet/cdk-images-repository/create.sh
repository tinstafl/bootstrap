#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <region> <alias>"
    exit 1
fi

account="$1"
region="$2"
alias="$3"

repository_name="tinstafl-$(echo "$alias" | tr '[:upper:]' '[:lower:]')"

echo "creating ecr repository: $repository_name"
if ! create_output=$(aws ecr create-repository --repository-name "$repository_name" --region "$region" --no-cli-pager 2>&1); then
    echo -e "${red}failed to create ecr repository: $create_output${nc}"
    exit 1
fi

policy_document=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$account:role/tinstafl-exec-$alias"
            },
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeRepositories"
            ]
        }
    ]
}
EOF
)

if ! echo "$policy_document" | jq . >/dev/null 2>&1; then
    echo -e "${red}invalid json policy document.${nc}"
    exit 1
fi

echo "attaching policy to ecr repository: $repository_name"
if ! set_policy_output=$(aws ecr set-repository-policy --repository-name "$repository_name" --policy-text "$policy_document" --region "$region" 2>&1); then
    echo -e "${red}failed to attach policy to ecr repository: $set_policy_output${nc}"
    exit 1
fi

echo -e "${green}successfully attached policy to ecr repository: $repository_name${nc}"
