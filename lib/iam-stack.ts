import * as cdk from "aws-cdk-lib"
import { Role } from "aws-cdk-lib/aws-iam"
import { Construct } from "constructs"
import { CdkAssetsRoleConstruct } from "./iam/assets"
import { CdkLookupRoleConstruct } from "./iam/lookup"
import { CdkImagesRoleConstruct } from "./iam/images"
import { CdkHandshakeRoleConstruct } from "./iam/handshake"
import { CdkDeployRoleConstruct } from "./iam/deploy"
import { CdkExecRoleConstruct } from "./iam/exec"
import { CdkYeetExecRoleConstruct } from "./iam/yeet-exec"
import { CdkSaasyExecRoleConstruct } from "./iam/saasy-exec"

export class TinstaflRoles extends cdk.NestedStack {
  public handshake: Role
  public lookup: Role
  public assets: Role
  public images: Role
  public deploy: Role
  public exec: Role
  public yeetExec: Role
  public saasyExec: Role

  constructor(scope: Construct, id: string, props?: cdk.NestedStackProps) {
    super(scope, id + "-roles", props)

    this.handshake = new CdkHandshakeRoleConstruct(scope, id).role
    this.lookup = new CdkLookupRoleConstruct(scope, id).role
    this.assets = new CdkAssetsRoleConstruct(scope, id).role
    this.images = new CdkImagesRoleConstruct(scope, id).role
    this.deploy = new CdkDeployRoleConstruct(scope, id).role
    this.exec = new CdkExecRoleConstruct(scope, id).role
    this.yeetExec = new CdkYeetExecRoleConstruct(scope, id).role
    this.saasyExec = new CdkSaasyExecRoleConstruct(scope, id).role
  }
}
