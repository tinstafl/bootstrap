# bootstrap

tinstafl bootstrap resources and scripts

The `cdk.json` file tells the CDK Toolkit how to execute your app.
Customize `cdk.context.json` to scope access by create, update and delete.

## useful commands

* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `npx cdk deploy`  deploy this stack to your default AWS account/region
* `npx cdk diff`    compare deployed stack with current state
* `npx cdk synth`   emits the synthesized CloudFormation template

### bind saasy release

lookup resources and generate `amplify.ts` file to use with saasy release infrastructure and nextjs ui

```shell
# generate amplify.ts configuration for saasy release
scripts/saasy/bind.sh -p <resource-prefix> -r <region>
```
