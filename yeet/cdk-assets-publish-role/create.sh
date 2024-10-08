#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
nc="\033[0m"

usage() {
    echo -e "${yellow}usage: $0 <account> <region> <api-key> <alias>${nc}"
    exit 1
}

if [ "$#" -lt 4 ]; then
    usage
fi

policy_dir="./policy"

account="$1"
region="$2"
external_id="$3"
alias="$4"

role_name="tinstafl-assets-$alias"

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

create_role() {
    local role_name="$1"
    local trust_policy="$2"

    if ! aws iam create-role --no-cli-pager --role-name "$role_name" --assume-role-policy-document "$trust_policy" 2>error.log; then
        echo -e "${red}failed to create role: $role_name${nc}"
        exit 1
    fi
}

attach_policy() {
    local policy_file="$1"
    local role_name="$2"
    local account="$3"
    local region="$4"
    local alias="$5"

    if [ ! -f "$policy_file" ]; then
        echo "policy file not found: $policy_file"
        return
    fi

    local iam_policy
    iam_policy=$(<"$policy_file")
    iam_policy=${iam_policy//\$account/$account}
    iam_policy=${iam_policy//\$region/$region}
    iam_policy=${iam_policy//\$alias/$alias}

    if [ -z "$iam_policy" ]; then
        echo "policy document is empty for file: $policy_file"
        return
    fi

    if ! echo "$iam_policy" | jq . > /dev/null; then
        echo "invalid json in policy file: $policy_file"
        return
    fi

    local policy_name
    policy_name=$(basename "$policy_file" .json)

    if ! aws iam put-role-policy --role-name "$role_name" --policy-name "$policy_name" --policy-document "$iam_policy" 2>error.log; then
        echo -e "${red}failed to attach policy: $policy_name to role: $role_name${nc}"
        cat error.log
    else
        echo -e "${green}successfully attached policy: $policy_name to role: $role_name${nc}"
    fi
}

create_role "$role_name" "$trust_policy"

if [ ! -d "$policy_dir" ]; then
    echo "policy directory not found: $policy_dir"
    exit 1
fi

attach_policy "$policy_dir/kms.json" "$role_name" "$account" "$region" "$alias"
attach_policy "$policy_dir/s3.json" "$role_name" "$account" "$region" "$(echo "$alias" | tr '[:upper:]' '[:lower:]')"
