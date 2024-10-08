#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "usage: $0 <account> <region> <external-id>"
    exit 1
fi

ACCOUNT="$1"
REGION="$2"
EXTERNAL_ID="$3"

colors=(
    "\033[0;31m"
    "\033[0;32m"
    "\033[0;34m"
    "\033[0;33m"
    "\033[0;35m"
    "\033[0;36m"
)

RESET="\033[0m"

dir="$1"
color_index=0

./kms.sh "$ACCOUNT" "$EXTERNAL_ID"
color_index=$(( (color_index + 1) % ${#colors[@]} ))
printf "%b creating kms key %s%b\n" "${colors[$color_index]}" "$dir" "$RESET"

./ssm.sh "$ACCOUNT" "$REGION" "$EXTERNAL_ID" 20
color_index=$(( (color_index + 1) % ${#colors[@]} ))
printf "%b creating ssm parameter %s%b\n" "${colors[$color_index]}" "$dir" "$RESET"
