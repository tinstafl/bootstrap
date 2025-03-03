import { Construct } from "constructs"
import * as ecr from "aws-cdk-lib/aws-ecr"
import { Repository } from "aws-cdk-lib/aws-ecr"
import * as iam from "aws-cdk-lib/aws-iam"
import { RemovalPolicy } from "aws-cdk-lib"

export class ImagesRepo extends Construct {
  public repository: Repository

  constructor(scope: Construct, id: string) {
    super(scope, id)

    const t = this.target()
    const name = `${ id }-${ t.name.toLowerCase() }`

    this.repository = new ecr.Repository(this, name, {
      repositoryName: name,
      removalPolicy: RemovalPolicy.DESTROY
    })

    const principals = []
    if (t.releases.includes("all"))
      principals.push(new iam.ArnPrincipal(`arn:aws:iam::${ t.account }:role/${ id }-${ t.name }-exec`))
    if (t.releases.includes("yeet"))
      principals.push(new iam.ArnPrincipal(`arn:aws:iam::${ t.account }:role/${ id }-${ t.name }-yeet-exec`))
    if (t.releases.includes("saasy"))
      principals.push(new iam.ArnPrincipal(`arn:aws:iam::${ t.account }:role/${ id }-${ t.name }-saasy-exec`))

    this.repository.addToResourcePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
        ],
        principals: principals,
      }))
  }

  private target() {
    const synthesizer = this.node.getContext("synthesizer")

    return {
      account: synthesizer.account,
      name: synthesizer.name,
      region: synthesizer.region,
      externalId: synthesizer.externalId,
      subscriberRoleArn: synthesizer.subscriberRoleArn,
      releases: synthesizer.releases
    }
  }
}
