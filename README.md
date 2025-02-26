<!-- markdownlint-disable MD041 MD033 -->

<p align="center">
  <img alt="Sombra" src="https://i.imgur.com/XNpxany.png"/>
</p>
<h1 align="center">Deploy Sombra with Terraform</h1>
<p align="center">
  <strong>Self-host Sombra to encrypt user data before it leaves your firewall.</strong><br /><br />
  <i>Built by security engineers with a healthy sense of paranoia.</i>
</p>
<p align="center">
  <a href="https://registry.terraform.io/modules/transcend-io/sombra/aws">
    <img alt="Sombra Terraform Module" src="https://i.imgur.com/9FUrMcN.png" height="206px"><br>
    View on the Terraform Module Registry
  </a>
</p>
<br />

> [!NOTE]
> We now recommend using our Helm chart to deploy Sombra: https://github.com/transcend-io/helm-charts. This module still works in many cases, but may not always be fully up-to-date.

## Motivation

Sombra provides the same security guarantees as going completely on-premise, but with a simple, lightweight gateway that performs cryptographic operations. By hosting Sombra on-prem, you don't have to trust Transcend. Sombra verifies that any incoming webhooks from Transcend were consented to by the user and verified by a trusted identity provider. It passes on the verified webhooks to any destination server or script inside the company firewall. When it's time to upload data to Transcend's cloud, Sombra encrypts the data before it leaves the firewall with a key that is only known to Sombra. Since Transcend doesn't have the decryption keys, Transcend employees have no means of seeing the data.

![Difference between a normal API and an API with Sombra in the middle](https://user-images.githubusercontent.com/7354176/65302016-a386a680-db2e-11e9-9457-c46af7de4ab7.png)

## LLM Classifier

Deploying the LLM Classifier is optional, and can be done with the following steps:

- Set the `deploy_llm` variable to `true`
- Customize the `llm_classifier_ecr_image` variable if you are using docker.transcend.io or want to customize the version tag
- Customize the EC2 instance type used if you'd like via the `llm_classifier_instance_type` variable.

Please note that there are considerable cost implications, as the LLM Classifier is a GPU-based system.

## Examples

We have an example of deploying Sombra in the `./example` folder`.

## Releases

To release a new version of the module to the Terraform Module registry, simply create a new Github release [here](https://github.com/transcend-io/terraform-aws-sombra/releases/new). CI will automatically pick up this release & publish to registry.terraform.io

<p align="center">
  <br />
  <i>Copyright © 2020 Transcend Inc.</i>
</p>