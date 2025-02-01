import { Construct } from "constructs"
import * as cdk from "aws-cdk-lib"
import { RemovalPolicy } from "aws-cdk-lib"
import { TinstaflRoles } from "./iam-stack"
import { TinstaflStorage } from "./storage-stack"
import { TinstaflKeys } from "./keys-stack"

export class BootstrapStack extends cdk.Stack {
  public roles: TinstaflRoles
  public storage: TinstaflStorage
  public keys: TinstaflKeys

  constructor(scope: Construct, id: string, name: string, props?: cdk.StackProps) {
    super(scope, id + `-${ name }`, props)

    this.roles = new TinstaflRoles(this, "tinstafl", {
      description: "cdk roles required for tinstafl releases",
      removalPolicy: RemovalPolicy.DESTROY
    })

    this.storage = new TinstaflStorage(this, "tinstafl", {
      description: "cdk storage required for tinstafl releases",
      removalPolicy: RemovalPolicy.DESTROY
    })

    this.keys = new TinstaflKeys(this, "tinstafl", {
      description: "cdk keys required for tinstafl releases",
      removalPolicy: RemovalPolicy.DESTROY
    })

    this.storage.ecr.node.addDependency(this.roles)

    const required = {
      roles: {
        handshake: this.roles.handshake.roleArn,
        lookup: this.roles.lookup.roleArn,
        assets: this.roles.assets.roleArn,
        images: this.roles.images.roleArn,
        deploy: this.roles.deploy.roleArn,
        exec: this.roles.exec?.roleArn,
        yeetExec: this.roles.yeetExec?.roleArn,
        saasyExec: this.roles.saasyExec?.roleArn,
      },
      storage: {
        assets: this.storage.s3.bucket.bucketArn,
        images: this.storage.ecr.repository.repositoryArn,
      },
      keys: {
        kms: {
          key: this.keys.kms.key.keyArn,
          alias: this.keys.kms.alias.aliasName
        },
        ssm: {
          parameter: this.keys.ssm.parameter.parameterArn
        }
      }
    }

    new cdk.CfnOutput(this, "tinstafl-resources", {
      key: "tinstafl",
      value: JSON.stringify(required),
    })
  }
}
