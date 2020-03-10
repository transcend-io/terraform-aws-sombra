<!-- markdownlint-disable MD041 MD033 -->

<p align="center">
    <img alt="Sombra" src="https://i.imgur.com/g3vxyZ0.png" height="200px"/>
</p>
<h1 align="center">Deploy Sombra with Terraform</h1>
<p align="center">
  <strong>Self-host Sombra to encrypt user data before it leaves your firewall.</strong><br /><br />
  <i>Built by security engineers with a healthy sense of paranoia.</i>
</p>
<p align="center">
  <a href="https://registry.terraform.io/modules/transcend-io/sombra/aws">
    <img alt="Sombra Terraform Module" src="https://i.imgur.com/jPbpAhr.png">
    View on the Terraform Module Registry
  </a>
</p>
<br />

## Motivation

Sombra provides the same security guarantees as going completely on-premise, but with a simple, lightweight gateway that performs cryptographic operations. By hosting Sombra on-prem, you don't have to trust Transcend. Sombra verifies that any incoming webhooks from Transcend were consented to by the user and verified by a trusted identity provider. It passes on the verified webhooks to any destination server or script inside the company firewall. When it's time to upload data to Transcend's cloud, Sombra encrypts the data before it leaves the firewall with a key that is only known to Sombra. Since Transcend doesn't have the decryption keys, Transcend employees have no means of seeing the data.

![Difference between a normal API and an API with Sombra in the middle](https://user-images.githubusercontent.com/7354176/65302016-a386a680-db2e-11e9-9457-c46af7de4ab7.png)

## External Application

This is a logically separated application with an open port on the internet that is only accessible by Transcend. Performing any operation on the data subject's personal data requires authorization (or consent) from an authenticated data subject.

The external application is responsible for *receiving* all communications from Transcend. Any webhook comes through here as well as operations related to the data subject's data download step.

## Internal Application

This is a logically separated application with one open port on the company private network. Only internal clients can use these ports (when `var.use_private_load_balancer` is set to `true`). There is also the option to add an internal password to prevent accidental or unauthorized access from clients in the private network.

## Using Sombra in a Separate VPC

You need to be able to communicate with Sombra's internal load balancer and port from your backend. There are two options:

1. You can leave `var.use_private_load_balancer` set to false, which will allow you to talk to sombra over TCP. If you go this route, make sure to set `var.incoming_cidr_ranges` to the public DNS CIDR blocks for your backend.
2. You can communicate through a VPC Peering Connection. This way, all of your communication with the internal ALB can happen over private DNS. To accomplish this, you'll need to:

- Set up VPC peering. I'd recommend checking out <https://registry.terraform.io/modules/cloudposse/vpc-peering/aws/0.3.0>
- Set `var.use_private_load_balancer` to true on this module
- Make sure your backends security group can communicate to private subnet CIDR blocks from the VPC containing this module
- Set `var.incoming_cidr_ranges` to be the private CIDR blocks from your backend's VPC
- Add your backend's VPC to the private hosted zone association, with something like:

```hcl
resource "aws_route53_zone_association" "private_sombra_zone" {
  zone_id = module.sombra.private_zone_id
  vpc_id  = module.your_peered_vpc.vpc_id
}
```

After that, you can reference the `internal_url` output from your backend over HTTPS.

<p align="center">
  <br />
  <i>Copyright © 2020 Transcend Inc.</i>
</p>
