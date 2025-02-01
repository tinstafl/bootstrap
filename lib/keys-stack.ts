import { Construct } from "constructs"
import * as cdk from "aws-cdk-lib"
import { CdkEncryptionKey } from "./kms/key"
import { CdkVersionParameter } from "./ssm/parameter"

export class TinstaflKeys extends cdk.NestedStack {
  public kms: CdkEncryptionKey
  public ssm: CdkVersionParameter

  constructor(scope: Construct, id: string, props?: cdk.NestedStackProps) {
    super(scope, id + "-keys", props)

    this.kms = new CdkEncryptionKey(scope, id)
    this.ssm = new CdkVersionParameter(scope, id)
  }
}