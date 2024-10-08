#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
blue="\033[0;34m"
yellow="\033[0;33m"
purple="\033[0;35m"
cyan="\033[0;36m"
nc="\033[0m"

colors=("$cyan" "$purple" "$blue" "$yellow" "$green" "$red")

usage() {
    echo "usage: $0 <account> <region> <api-key> <subscriber-role-arn>"
    exit 1
}

if [ "$#" -lt 4 ]; then
    usage
fi

account="$1"
region="$2"
api_key="$3"
subscriber_role_arn="$4"

color_index=0

run_create() {
    local dir="$1"
    shift
    local params=("$@")
    printf "%b creating %s resources >>> %b\n" "${colors[$color_index]}" "$dir" "$nc"

    if cd "$dir" && ./create.sh "${params[@]}"; then
        echo -e "${green}successfully created resources in $dir${nc}"
    else
        echo -e "${red}failed to create resources in $dir${nc}"
        exit 1
    fi

    cd - > /dev/null || exit
    color_index=$(( (color_index + 1) % ${#colors[@]} ))
}

echo -e "\n\n"

run_create "yeet" "$account" "$region" "$api_key" "$subscriber_role_arn"

echo -e "\n\n"
