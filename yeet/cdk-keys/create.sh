#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <region> <alias>"
    exit 1
fi

account="$1"
region="$2"
alias="$3"

red="\033[0;31m"
green="\033[0;32m"
nc="\033[0m"

log_success() {
    printf "%b%s%b\n" "$green" "$1" "$nc"
}

log_error() {
    printf "%berror: %s%b\n" "$red" "$1" "$nc"
}

dir="$1"

if ./kms.sh "$account" "$alias"; then
    log_success "successfully created kms key: $dir"
else
    log_error "failed to create kms key: $dir"
    exit 1
fi

if ./ssm.sh "$account" "$region" "$alias" 21; then
    log_success "successfully created ssm parameter: $dir"
else
    log_error "failed to create ssm parameter: $dir"
    exit 1
fi
