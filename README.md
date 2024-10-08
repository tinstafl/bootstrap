# bootstrap

## overview

```bash
# bash, zsh, aws cli, and jq versions
bash --version
# gnu bash, version 5.2.26(1)-release (aarch64-apple-darwin23.2.0)

zsh --version
# zsh 5.9 (x86_64-apple-darwin23.0)

aws --version
# aws-cli/2.15.53 python/3.11.8 darwin/23.6.0 exe/x86_64

jq --version
# jq-1.7.1
```

### create resources

#### aws cdk bootstrap resources

these roles facilitate cross-account access and are scoped to use the aws services and actions required for tinstafl
system deployments.

- **aws account id**:
    - the aws account id for the resources to be deployed to this account.

- **region**:
    - the aws account region where the resources are located.

- **api key**:
    - the subscriber api key generated upon subscription.
    - the external id used for establishing trust relationships between roles.

- **subscriber role arn**:
    - iam role that enables tinstafl access to a subscriber's configured aws account, provided a valid external id (api
      key) is used.

- **alias**:
    - unique identifier that supports account/team modularity for tinstafl bootstrap resources.

### create all resources

```bash
./create.sh <aws-account-id> <region> <api-key> <subscriber-role-arn> <alias>
```

### delete all resources

```bash
./delete.sh <alias>
```

### only yeet

```bash
cd yeet

# create all resources
./create.sh <aws-account-id> <region> <api-key> <subscriber-role-arn> <alias>

# delete all resources
./delete.sh <alias>
```

### only saasy

```bash
cd saasy

# create all resources
./create.sh <aws-account-id> <region> <api-key> <subscriber-role-arn> <alias>

# delete all resources
./delete.sh <alias>
```

### (optional) eks/grafana integration

cloud access policies can be created with the grafana cloud console or via the grafana cloud api if you have enabled a
cloud access policy, `accesspolicies:write`. if access is enabled, you can run the `yeet/grafana/create.sh` script to
create a grafana cloud access policy and an aws secret for tinstafl to use for eks monitoring. tinstafl will install the
grafana cloud helm chart and use these secrets to enable access.

- **grafana cloud access policy token**:
    - [grafana access policies documentation](https://grafana.com/docs/grafana-cloud/account-management/authentication-and-permissions/access-policies/).
    - the token should have permissions `accesspolicies:write`.

- **grafana cloud instance id**:
    - visit [grafana cloud instance details](https://grafana.com/orgs/{your-organization}) and check out your
      organization level details here https://grafana.com/api/orgs/{your-organization}.

- **grafana region**:
    - [grafana stack regions](https://grafana.com/api/stack-regions)
    - [grafana cloud regional availability](https://grafana.com/docs/grafana-cloud/account-management/regional-availability/)

update/create new inputs.json with grafana service details

```json
{
  "cloud_access_policy_token": "glc_abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
  "prometheus_host": "https://prometheus-prod-1-prod-us-west-0.grafana.net",
  "prometheus_username": "0000001",
  "loki_host": "https://logs-prod-1.grafana.net",
  "loki_username": "000001",
  "tempo_host": "https://tempo-prod-1-prod-us-west-0.grafana.net:443",
  "tempo_username": "000001",
  "alias": "abcdefg",
  "instance_id": "000001",
  "region": "prod-us-west-0"
}
```

```bash
cd yeet/grafana

./create.sh inputs.json
```

or use the console 'grafana play'
walkthrough: [grafana play walkthrough](https://play.grafana.org/a/grafana-k8s-app/configuration) and manually create an
aws secret for tinstafl to use

```json
{
    "key": "$cloud_access_policy_token",
    "lokiHost": "$loki_host",
    "lokiUsername": "$loki_username",
    "prometheusHost": "$prometheus_host",
    "prometheusUsername": "$prometheus_username",
    "tempoHost": "$tempo_host",
    "tempoUsername": "$tempo_username"
}
```

tinstafl will use this secret to configure grafana integration with the k8s-monitoring open source helm chart to enable
monitoring
