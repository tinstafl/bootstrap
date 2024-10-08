#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <region> <external-id> <subscriber-arn>"
    exit 1
fi

ACCOUNT="$1"
REGION="$2"
EXTERNAL_ID="$3"
SUBSCRIBER_ARN="$4"

colors=(
    "\033[0;31m"
    "\033[0;32m"
    "\033[0;34m"
    "\033[0;33m"
    "\033[0;35m"
    "\033[0;36m"
)

RESET="\033[0m"

color_index=0

run_create() {
    local dir="$1"
    printf "%b creating %s >>> %b\n" "${colors[$color_index]}" "$dir" "$RESET"
    cd "$dir" || exit

    IFS=' ' read -r -a params <<< "$2"

    ./create.sh "${params[@]}"
    cd - || exit

    color_index=$(( (color_index + 1) % ${#colors[@]} ))
}

printf "\n\n"

run_create "cdk-handshake-role" "$ACCOUNT $EXTERNAL_ID $SUBSCRIBER_ARN"
printf "\n\n"

run_create "cdk-exec-role" "$ACCOUNT $EXTERNAL_ID"
printf "\n\n"

run_create "cdk-deploy-role" "$ACCOUNT $REGION $EXTERNAL_ID"
printf "\n\n"

run_create "cdk-lookup-role" "$ACCOUNT $EXTERNAL_ID"
printf "\n\n"

run_create "cdk-file-publish-role" "$ACCOUNT $REGION $EXTERNAL_ID"
printf "\n\n"

run_create "cdk-image-publish-role" "$ACCOUNT $REGION $EXTERNAL_ID"
printf "\n\n"

run_create "cdk-keys" "$ACCOUNT $REGION $EXTERNAL_ID"
printf "\n\n"

run_create "cdk-assets-bucket" "$REGION $EXTERNAL_ID"
printf "\n\n"

run_create "cdk-images-repository" "$ACCOUNT $REGION $EXTERNAL_ID"
printf "\n\n"
