#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <account> <alias>"
    exit 1
fi

account="$1"
alias="$2"
role_name="tinstafl-exec-$alias"
policy_dir="./policy"

trust_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudformation.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
)

if ! aws iam create-role --no-cli-pager --role-name "$role_name" --assume-role-policy-document "$trust_policy" 2>error.log; then
    echo -e "${red}failed to create role: $role_name${nc}"
    exit 1
fi

if [ ! -d "$policy_dir" ]; then
    echo -e "${red}policy directory not found: $policy_dir${nc}"
    exit 1
fi

for policy_file in "$policy_dir"/*.json; do
    if [ ! -f "$policy_file" ]; then
        echo -e "${red}no policy files found in directory: $policy_dir${nc}"
        continue
    fi

    iam_policy=$(<"$policy_file")
    iam_policy=${iam_policy//\$account/$account}

    if [ -z "$iam_policy" ]; then
        echo -e "${red}policy document is empty for file: $policy_file${nc}"
        continue
    fi

    if ! echo "$iam_policy" | jq . > /dev/null; then
        echo -e "${red}invalid json in policy file: $policy_file${nc}"
        continue
    fi

    policy_name=$(basename "$policy_file" .json)

    if ! aws iam put-role-policy --role-name "$role_name" --policy-name "$policy_name" --policy-document "$iam_policy" 2>error.log; then
        echo -e "${red}failed to attach policy: $policy_name to role: $role_name${nc}"
        cat error.log
    else
        echo -e "${green}successfully attached policy: $policy_name to role: $role_name${nc}"
    fi
done
