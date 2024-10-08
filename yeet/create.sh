#!/bin/bash

export LC_ALL=C

red="\033[0;31m"
green="\033[0;32m"
blue="\033[0;34m"
yellow="\033[0;33m"
purple="\033[0;35m"
cyan="\033[0;36m"
reset="\033[0m"

colors=("$red" "$green" "$blue" "$yellow" "$purple" "$cyan")

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

alias=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 1)$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 7)

color_index=0

run_create() {
    local dir="$1"
    shift
    local params=("$@")

    printf "%b creating %s >>> %b\n" "${colors[$color_index]}" "$dir" "$reset"

    if cd "$dir" && ./create.sh "${params[@]}"; then
        echo -e "${green}successfully created resources in $dir${reset}"
    else
        echo -e "${red}failed to create resources in $dir${reset}"
        exit 1
    fi

    cd - > /dev/null || exit
    color_index=$(( (color_index + 1) % ${#colors[@]} ))
}

cat << "EOF"

                  ___           ___
                 /\__\         /\__\
      ___       /:/ _/_       /:/ _/_         ___
     /|  |     /:/ /\__\     /:/ /\__\       /\__\
    |:|  |    /:/ /:/ _/_   /:/ /:/ _/_     /:/  /
    |:|  |   /:/_/:/ /\__\ /:/_/:/ /\__\   /:/__/
  __|:|__|   \:\/:/ /:/  / \:\/:/ /:/  /  /::\  \
 /::::\  \    \::/_/:/  /   \::/_/:/  /  /:/\:\  \
 ~~~~\:\  \    \:\/:/  /     \:\/:/  /   \/__\:\  \
      \:\__\    \::/  /       \::/  /         \:\__\
       \/__/     \/__/         \/__/           \/__/

EOF

echo -e "\n\n"

run_create "cdk-handshake-role" "$account" "$region" "$api_key" "$subscriber_role_arn" "$alias"
echo -e "\n\n"

run_create "cdk-exec-role" "$account" "$alias"
echo -e "\n\n"

run_create "cdk-deploy-role" "$account" "$region" "$api_key" "$alias"
echo -e "\n\n"

run_create "cdk-lookup-role" "$account" "$api_key" "$alias"
echo -e "\n\n"

run_create "cdk-assets-publish-role" "$account" "$region" "$api_key" "$alias"
echo -e "\n\n"

run_create "cdk-images-publish-role" "$account" "$region" "$api_key" "$alias"
echo -e "\n\n"

run_create "cdk-keys" "$account" "$region" "$alias"
echo -e "\n\n"

run_create "cdk-assets-bucket" "$region" "$alias"
echo -e "\n\n"

run_create "cdk-images-repository" "$account" "$region" "$alias"
echo -e "\n\n"
