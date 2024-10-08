#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <external-id> <kms-key-id>"
    exit 1
fi

external_id="$1"

handshake_role_name="tinstafl-handshake-$external_id"
cdk_exec_role_name="tinstafl-exec-$external_id"
cdk_deploy_role_name="tinstafl-deploy-$external_id"
cdk_lookup_role_name="tinstafl-lookup-$external_id"
cdk_image_publish_role_name="tinstafl-images-$external_id"
cdk_file_publish_role_name="tinstafl-assets-$external_id"

ssm_parameter_name="/cdk/tinstafl-$external_id/version"
kms_key_alias="alias/tinstafl-$external_id"
kms_key_id="$2"
bucket_name="tinstafl-$(echo "$external_id" | tr '[:upper:]' '[:lower:]')"
ecr_repo_name="tinstafl-$(echo "$external_id" | tr '[:upper:]' '[:lower:]')"

delete_iam_role() {
    local role_name="$1"

    echo "detaching policies from iam role: $role_name"
    managed_policies=$(aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[*].PolicyArn' --output text)

    for policy in $managed_policies; do
        echo "detaching managed policy: $policy from role: $role_name"
        aws iam detach-role-policy --role-name "$role_name" --policy-arn "$policy" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "failed to detach managed policy: $policy from role: $role_name"
        else
            echo "successfully detached managed policy: $policy from role: $role_name"
        fi
    done

    inline_policies=$(aws iam list-role-policies --role-name "$role_name" --query 'PolicyNames' --output text)

    for policy in $inline_policies; do
        echo "deleting inline policy: $policy from role: $role_name"
        aws iam delete-role-policy --role-name "$role_name" --policy-name "$policy" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "failed to delete inline policy: $policy from role: $role_name"
        else
            echo "successfully deleted inline policy: $policy from role: $role_name"
        fi
    done

    echo "deleting iam role: $role_name"
    aws iam delete-role --role-name "$role_name" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "failed to delete role: $role_name"
    else
        echo "successfully deleted role: $role_name"
    fi
}

delete_ssm_parameter() {
    echo "deleting ssm parameter: $ssm_parameter_name"
    aws ssm delete-parameter --name "$ssm_parameter_name" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "failed to delete ssm parameter: $ssm_parameter_name"
    else
        echo "successfully deleted ssm parameter: $ssm_parameter_name"
    fi
}

delete_kms_key_alias() {
    echo "deleting kms key alias: $kms_key_alias"
    aws kms delete-alias --no-cli-pager --alias-name "$kms_key_alias" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "failed to delete kms key alias: $kms_key_alias"
    else
        echo "successfully deleted kms key alias: $kms_key_alias"
    fi
}

delete_kms_key() {
    echo "scheduling kms key for deletion: $kms_key_id"
    aws kms schedule-key-deletion --no-cli-pager --key-id "$kms_key_id" --pending-window-in-days 7 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "failed to schedule deletion of kms key: $kms_key_id"
    else
        echo "successfully scheduled deletion of kms key: $kms_key_id"
    fi
}

delete_s3_bucket() {
    echo "deleting s3 bucket: $bucket_name"
    aws s3 rm "s3://$bucket_name" --recursive 2>/dev/null
    aws s3api delete-bucket --no-cli-pager --bucket "$bucket_name" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "failed to delete s3 bucket: $bucket_name"
    else
        echo "successfully deleted s3 bucket: $bucket_name"
    fi
}

delete_ecr_repo() {
    echo "deleting ecr repository: $ecr_repo_name"
    aws ecr delete-repository --no-cli-pager --repository-name "$ecr_repo_name" --force 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "failed to delete ecr repository: $ecr_repo_name"
    else
        echo "successfully deleted ecr repository: $ecr_repo_name"
    fi
}

delete_iam_role "$handshake_role_name"
delete_iam_role "$cdk_exec_role_name"
delete_iam_role "$cdk_deploy_role_name"
delete_iam_role "$cdk_lookup_role_name"
delete_iam_role "$cdk_file_publish_role_name"
delete_iam_role "$cdk_image_publish_role_name"

delete_ssm_parameter
delete_kms_key_alias
delete_kms_key
delete_s3_bucket
delete_ecr_repo
