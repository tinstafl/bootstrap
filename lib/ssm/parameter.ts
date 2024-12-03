import { Construct } from "constructs"
import * as ssm from "aws-cdk-lib/aws-ssm"
import { StringParameter } from "aws-cdk-lib/aws-ssm"

export class CdkVersionParameter extends Construct {
  public parameter: StringParameter

  constructor(scope: Construct, id: string) {
    super(scope, id + "-cdk-version-parameter")

    const t = this.target()
    const name = `/cdk/${ id }-${ t.name }/version`

    this.parameter = new ssm.StringParameter(this, "cdk-version-parameter", {
      parameterName: name,
      stringValue: t.version,
      description: `cdk managed version parameter for ${ t.name }`,
    })
  }

  private target() {
    const synthesizer = this.node.getContext("synthesizer")

    return {
      name: synthesizer.name,
      version: synthesizer.cdk.version,
    }
  }
}
