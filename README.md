# Sombra

<p align="center">
    <img alt="Sombra" src="https://i.imgur.com/ABGyaWl.png" height="200px"/>
</p>
<h1 align="center">Sombra by Transcend</h1>
<p align="center">
  <strong>Encrypt user data before it leaves your firewall</strong><br /><br />
  <i>Sombra is a client-side cryptography appliance for data controllers to encrypt their data before sending it to Transcend. Built by paranoid engineers.</i>
</p>
<p align="center">
  <a href="https://registry.terraform.io/modules/transcend-io/sombra/aws">
    View on the Terraform Module Registry
  </a>
</p>
<br />

## Motivation

Sombra provides the same security guarantees as going completely on-premise, but with a simple, lightweight gateway that performs cryptographic operations. By hosting Sombra on-prem, data controllers don't have to trust Transcend. Sombra verifies that any incoming webhooks from Transcend were consented to by the user and verified by a trusted identity provider. It passes on the verified webhooks to any destination server or script inside the company firewall. When it's time to upload data to Transcend's cloud, Sombra encrypts the data before it leaves the firewall with a key that is only known to Sombra. Since Transcend doesn't have the decryption keys, Transcend employees have no means of seeing the data.

![Difference between a normal API and an API with Sombra in the middle](https://user-images.githubusercontent.com/7354176/65302016-a386a680-db2e-11e9-9457-c46af7de4ab7.png)

## External Application

This is a logically separated application with an open port on the internet that is only accessible by Transcend. This is ensured by two factors of authentication: (1) an ECDSA-signed token, verified with Transcend's public key and (2) TLS client authentication, which is an attestation from our Certificate Authority. Performing any operation on the data subject's personal data requires a third factor: authorization (consent) from an authenticated data subject.

The external application is responsible for *receiving* all communications from Transcend. Any webhook comes through here as well as operations related to the data subject's data download step.

![Step 1: Transcend notifies your systems of a new data request](https://i.imgur.com/qQyBvXG.png)

## Internal Application

This is a logically separated application with one open port on the company private network. Only internal clients can use these ports (when `var.use_private_load_balancer` is set to `true`). There is also the option to add an internal password to prevent accidental or unauthorized access from clients in the private network.

![Step 2: Your systems upload data to Transcend, via Sombra](https://i.imgur.com/5Ckqv2m.png)

<p align="center">
  <img alt="Sombra" src="https://i.imgur.com/t6rhSmW.png" height="300px" />
  <br />
  <i>Copyright © 2020 Transcend Inc.</i>
</p>