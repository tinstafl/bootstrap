#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() {
  echo -e "${YELLOW}$1${NC}"
}

log_success() {
  echo -e "${GREEN}$1${NC}"
}

log_failure() {
  echo -e "${RED}$1${NC}"
}

exit_with_error() {
  log_failure "Error: $1"
  exit 1
}

usage() {
  echo "Usage: $0 -p <resource_prefix> -r <aws_region>"
  exit 1
}

resource_prefix=""
aws_region=""

while getopts "p:r:" opt; do
  case ${opt} in
    p )
      resource_prefix=$OPTARG
      ;;
    r )
      aws_region=$OPTARG
      ;;
    \? )
      usage
      ;;
  esac
done

if [ -z "${resource_prefix:-}" ] || [ -z "${aws_region:-}" ]; then
  usage
fi

log "looking up aws resources with prefix: ${resource_prefix}"

log "looking up cognito user pool id..."
USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 50 --region "$aws_region" \
  --query "UserPools[?contains(Name, '${resource_prefix}')].Id" --output text)

if [ -z "$USER_POOL_ID" ]; then
  exit_with_error "no user pool found with prefix: $resource_prefix"
fi
log_success "found user pool id: $USER_POOL_ID"

log "looking up cognito user pool client id..."
USER_POOL_CLIENT_ID=$(aws cognito-idp list-user-pool-clients --user-pool-id "$USER_POOL_ID" --region "$aws_region" \
  --query "UserPoolClients[?contains(ClientName, '${resource_prefix}')].ClientId" --output text)

if [ -z "$USER_POOL_CLIENT_ID" ]; then
  exit_with_error "No User Pool Client found with prefix: $resource_prefix"
fi
log_success "found user pool client id: $USER_POOL_CLIENT_ID"

log "looking up cognito identity pool id..."
IDENTITY_POOL_ID=$(aws cognito-identity list-identity-pools --max-results 50 --region "$aws_region" \
  --query "IdentityPools[?contains(IdentityPoolName, '${resource_prefix}')].IdentityPoolId" --output text)

if [ -z "$IDENTITY_POOL_ID" ]; then
  exit_with_error "no identity pool found with prefix: $resource_prefix"
fi
log_success "found identity pool id: $IDENTITY_POOL_ID"

log "looking up api gateway rest api id..."
API_ID=$(aws apigateway get-rest-apis --region "$aws_region" \
  --query "items[?contains(name, '${resource_prefix}')].id" --output text)

if [ -z "$API_ID" ]; then
  exit_with_error "no api gateway found with prefix: $resource_prefix"
fi
log_success "found api gateway id: $API_ID"

STAGE="v1"
SERVICE="execute-api"

read -rp "enter the api name (default: '${resource_prefix}-api'): " API_NAME
API_NAME=${API_NAME:-"${resource_prefix}-api"}

cat <<EOF > amplify.ts
import { createServerRunner } from "@aws-amplify/adapter-nextjs"

export const API_NAME = '${API_NAME}'
export const USER_POOL_ID = '${USER_POOL_ID}'
export const USER_POOL_CLIENT_ID = '${USER_POOL_CLIENT_ID}'
export const IDENTITY_POOL_ID = '${IDENTITY_POOL_ID}'
export const API_ID = '${API_ID}'
export const REGION = '${aws_region}'
export const STAGE = '${STAGE}'
export const SERVICE = '${SERVICE}'

export const aws = () => {
  return {
    Auth: {
      Cognito: {
        userPoolId: USER_POOL_ID,
        userPoolClientId: USER_POOL_CLIENT_ID,
        identityPoolId: IDENTITY_POOL_ID,
        allowGuestAccess: false
      },
    },
    API: {
      REST: {
        [API_NAME]: {
          region: REGION,
          service: SERVICE,
          endpoint: \`https://\${API_ID}.execute-api.\${REGION}.amazonaws.com/\${STAGE}\`,
        }
      }
    }
  }
}

export const { runWithAmplifyServerContext } = createServerRunner({ config: aws() })
EOF

log_success "amplify.ts file generated successfully."
