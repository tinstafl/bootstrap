#!/usr/bin/env node

import "source-map-support/register"
import * as cdk from "aws-cdk-lib"
import { BootstrapStack } from "../lib/bootstrap-stack"

const app = new cdk.App()
const name = app.node.getContext("synthesizer")?.name

new BootstrapStack(app, "tinstafl", name, {
  env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION },
  description: "required resources to integrate with tinstafl releases"
})
