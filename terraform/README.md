# Purpose

We have multiple terraform projects, each is entirely isolated and serves a unique purpose

* [manual](./manual/README.md): This project simply bootstraps our terraform process, by creating some S3 Buckets on Cloudflare
* [github](./github/README.md): All our secrets (for development/production, etc) are managed through IaC.  This project manages *all* secrets.
* [talos](./talos/README.md): This will manage the configuration and provisioning of our development and production cluster.  Once finished, we will have a running kubernetes cluster.
