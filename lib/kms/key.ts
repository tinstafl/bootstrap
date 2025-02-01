import { Construct } from "constructs"
import * as cdk from "aws-cdk-lib"
import * as kms from "aws-cdk-lib/aws-kms"
import { Alias, Key } from "aws-cdk-lib/aws-kms"
import * as iam from "aws-cdk-lib/aws-iam"

export class CdkEncryptionKey extends Construct {
  public key: Key
  public alias: Alias

  constructor(scope: Construct, id: string) {
    super(scope, id + "-cdk-kms-encryption-key")

    const t = this.target()
    const name = `alias/${ id }-${ t.name.toLowerCase() }`

    this.key = new kms.Key(this, "cdk-kms-encryption-key", {
      description: "kms key for cdk toolchain",
      keyUsage: kms.KeyUsage.ENCRYPT_DECRYPT,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      rotationPeriod: cdk.Duration.days(365)
    })

    this.alias = new kms.Alias(this, "kms-key-alias", {
      aliasName: name,
      targetKey: this.key,
    })

    const keyPolicyStatement = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
      ],
      resources: [ "*" ],
      principals: [
        new iam.ServicePrincipal("cloudformation.amazonaws.com"),
        new iam.ServicePrincipal("codepipeline.amazonaws.com"),
        new iam.ServicePrincipal("codedeploy.amazonaws.com"),
      ],
    })

    const accountPolicyStatement = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [ "kms:*" ],
      resources: [ "*" ],
      principals: [ new iam.AccountPrincipal(t.account) ],
    })

    this.key.addToResourcePolicy(keyPolicyStatement)
    this.key.addToResourcePolicy(accountPolicyStatement)
  }

  private target() {
    const synthesizer = this.node.getContext("synthesizer")

    return {
      account: synthesizer.account,
      name: synthesizer.name,
    }
  }
}
