import { Construct } from "constructs"
import { ImagesRepo } from "./ecr/repo"
import { AssetsBucket } from "./s3/bucket"
import * as cdk from "aws-cdk-lib"

export class TinstaflStorage extends cdk.NestedStack {
  public ecr: ImagesRepo
  public s3: AssetsBucket

  constructor(scope: Construct, id: string, props?: cdk.NestedStackProps) {
    super(scope, id+ "-storage", props)

    this.ecr = new ImagesRepo(scope, id)
    this.s3 = new AssetsBucket(scope, id)
  }
}