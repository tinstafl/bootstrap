#!/bin/bash

green='\e[32m'
red='\e[31m'
nc='\e[0m'

log_success() {
    printf "%b%s%b\n" "$green" "$1" "$nc"
}

log_error() {
    printf "%berror: %s%b\n" "$red" "$1" "$nc"
}

if [ "$#" -lt 1 ]; then
    log_error "usage: $0 <alias>"
    exit 1
fi

alias="$1"
handshake_role_name="tinstafl-handshake-$alias"
cdk_exec_role_name="tinstafl-exec-$alias"
cdk_deploy_role_name="tinstafl-deploy-$alias"
cdk_lookup_role_name="tinstafl-lookup-$alias"
cdk_image_publish_role_name="tinstafl-images-$alias"
cdk_file_publish_role_name="tinstafl-assets-$alias"
ssm_parameter_name="/cdk/tinstafl-$alias/version"
kms_key_alias="alias/tinstafl-$alias"
bucket_name="tinstafl-$(echo "$alias" | tr '[:upper:]' '[:lower:]')"
ecr_repo_name="tinstafl-$(echo "$alias" | tr '[:upper:]' '[:lower:]')"

delete_iam_role() {
    local role_name="$1"
    echo "detaching policies from iam role: $role_name"
    managed_policies=$(aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[*].PolicyArn' --output text)

    for policy in $managed_policies; do
        echo "detaching managed policy: $policy from role: $role_name"
        if ! aws iam detach-role-policy --role-name "$role_name" --policy-arn "$policy"; then
            log_error "failed to detach managed policy: $policy from role: $role_name"
        else
            log_success "successfully detached managed policy: $policy from role: $role_name"
        fi
    done

    inline_policies=$(aws iam list-role-policies --role-name "$role_name" --query 'PolicyNames' --output text)

    for policy in $inline_policies; do
        echo "deleting inline policy: $policy from role: $role_name"
        if ! aws iam delete-role-policy --role-name "$role_name" --policy-name "$policy"; then
            log_error "failed to delete inline policy: $policy from role: $role_name"
        else
            log_success "successfully deleted inline policy: $policy from role: $role_name"
        fi
    done

    echo "deleting iam role: $role_name"
    if ! aws iam delete-role --role-name "$role_name"; then
        log_error "failed to delete role: $role_name"
    else
        log_success "successfully deleted role: $role_name"
    fi
}

delete_ssm_parameter() {
    echo "deleting ssm parameter: $ssm_parameter_name"
    if ! aws ssm delete-parameter --name "$ssm_parameter_name"; then
        log_error "failed to delete ssm parameter: $ssm_parameter_name"
    else
        log_success "successfully deleted ssm parameter: $ssm_parameter_name"
    fi
}

delete_kms_key() {
    echo "deleting kms key using alias: $kms_key_alias"
    kms_key_id=$(aws kms list-aliases --no-cli-pager --query "Aliases[?AliasName=='$kms_key_alias'].TargetKeyId" --output text)

    if [ -z "$kms_key_id" ]; then
        log_error "failed to find kms key id for alias: $kms_key_alias"
        return 1
    fi

    if ! aws kms delete-alias --no-cli-pager --alias-name "$kms_key_alias"; then
        log_error "failed to delete kms key alias: $kms_key_alias"
        return 1
    else
        log_success "successfully deleted kms key alias: $kms_key_alias"
    fi

    echo "scheduling kms key for deletion: $kms_key_id"
    if ! aws kms schedule-key-deletion --no-cli-pager --key-id "$kms_key_id" --pending-window-in-days 7; then
        log_error "failed to schedule deletion of kms key: $kms_key_id"
        return 1
    else
        log_success "successfully scheduled deletion of kms key: $kms_key_id"
    fi
}

delete_s3_bucket() {
    echo "deleting s3 bucket: $bucket_name"
    aws s3 rm "s3://$bucket_name" --recursive
    if ! aws s3api delete-bucket --no-cli-pager --bucket "$bucket_name"; then
        log_error "failed to delete s3 bucket: $bucket_name"
    else
        log_success "successfully deleted s3 bucket: $bucket_name"
    fi
}

delete_ecr_repo() {
    echo "deleting ecr repository: $ecr_repo_name"
    if ! aws ecr delete-repository --no-cli-pager --repository-name "$ecr_repo_name" --force; then
        log_error "failed to delete ecr repository: $ecr_repo_name"
    else
        log_success "successfully deleted ecr repository: $ecr_repo_name"
    fi
}

delete_iam_role "$handshake_role_name"
delete_iam_role "$cdk_exec_role_name"
delete_iam_role "$cdk_deploy_role_name"
delete_iam_role "$cdk_lookup_role_name"
delete_iam_role "$cdk_file_publish_role_name"
delete_iam_role "$cdk_image_publish_role_name"
delete_ssm_parameter
delete_kms_key
delete_s3_bucket
delete_ecr_repo
