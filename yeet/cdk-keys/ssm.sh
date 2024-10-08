#!/bin/bash

if [ "$#" -lt 4 ]; then
    echo "usage: $0 <account> <region> <alias> <version>"
    exit 1
fi

account="$1"
region="$2"
alias="$3"
version="$4"

red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

log_success() {
    printf "%b%s%b\n" "$green" "$1" "$nc"
}

log_error() {
    printf "%berror: %s%b\n" "$red" "$1" "$nc"
}

parameter_name="/cdk/tinstafl-$alias/version"
parameter_value="$version"

echo "creating ssm parameter: $parameter_name in region: $region"

if ! aws ssm put-parameter --no-cli-pager --name "$parameter_name" \
    --value "$parameter_value" \
    --type "String" \
    --region "$region" \
    --overwrite; then
    log_error "failed to create ssm parameter"
    exit 1
fi

parameter_arn="arn:aws:ssm:$region:$account:parameter$parameter_name"

log_success "ssm parameter created successfully. arn: $parameter_arn"
