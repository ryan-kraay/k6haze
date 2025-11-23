# Purpose

We have multiple terraform projects and each has their own [Environment Secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets#creating-secrets-for-an-environment).  These secrets are **all** managed via Infrastructure-as-Code and it is **this** project that will manage those secrets.

**WARNING**: These are hastily written notes, this documentation will need to be tested and refined (later).

# Setup

Unfortunately, the setup process is _not_ turn-key.

## Create an AGE secret

This age-key will be used to encrypt **all** secrets (as rest).  So, these are "the keys to the castle".  We will use Github Environment Secrets to isolate _who get to use this key_.

**NOTE**: As we're using SOPS you can also use something _other_ than Age (ie: KMS).  Details regarding, "How to do this" are left as an "exercise for the reader."

The process for creating an age-key is:

```bash
cd terraform/github/secrets
age-keygen > secret.key
edit .sops.yaml # and change `age: xxxxx` to be _your_ public key
cp secret.key curator/age.sops.env
edit age.sops.env # and prepend `SOPS_AGE_KEY=AGE-SECRET-KEY-....`
cat age.sops.env
``
# created: 2025-11-08T16:43:28+01:00
# public key: agexxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SOPS_AGE_KEY=AGE-SECRET-KEY-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
``
# Encrypt the age secret (with itself)
sops -e --in-line curator/age.sops.env
```

## Encrypt the Cloudflare Account ID

This information will be used when determining which api endpoint to access the S3 content for.

You can retrive this information by running:

```bash
cd manual
tofo output

# cloudflare_account_id="......"
```

Or you can retrive this from cloudflare's dashboard (TODO: describe this process)

Once you have it, run:

```bash
sops github/secrets/shared/cloudflare.sops.env
> TF_VAR_cloudflare_account_id="<cloudflare_account_id>"
```

## For each platform...

You'll need to construct:

1. A key to encrypt the terraform state file (if using OpenTofu)
2. Read/Write AWS Access keys to the S3 bucket

### Create an encrypt key for the terraform state file

This optional, but strongly recommended. And is **only** a feature in OpenTofu.  Basically, each S3 bucket will be reused for each platform.  For example, the `k6haze-production-tfstate` will contain the tfstate for using talos *and* another tfstate for managing kubernetes.

If these are not encrypted, it would mean that (in theory) the kubernetes terraform project could read the talos tfstate (which includes additional sensative information).

Unfortunately, ATM, Cloudflare R2 lacks the ability to limit AWS Access Keys to specific paths within the S3 Bucket.  The alternative would be to create dedicated S3 buckets for each `environment` and each `project` (re: `k6haze-production-talos-tfstate` and `k6haze-production-k8s-tfstate`)... but that seems like work.  Especially with all the manual steps currently involved.

Creating a key can be done in a variety of ways.  The way, I've chosen is simply to run:

```bash
tr -dc 'A-Za-z0-9_@#%-[]' < /dev/urandom | head -c 128; echo;
```

Stash this somewhere safe...

### AWS Access Keys

1. Log into [Cloudflare](https://dash.cloudflare.com/login).
2. Go to `build->Storage & Databases->R2 object store->Overview`
3. On the Right Side: `Account Details -> API Tokens -> { } Manage`
4. Click on "Create Account API token"
    1. Name: `YYYYMMDD R/W access to k6haze-curator-tfstate`
    2. Permissions: `Object Read & Write`
    3. Specify Bucket(s): `Apply to specific buckets only -> k6haze-curator-tfstate`
    4. TTL: `Forever`
    5. `Create Account API Token`
5. Capture the "Access Key ID" and "Secret Access Key"
6. Run `sops secrets/curator/tfstate.sops.env`
    1. Add: `AWS_ACCESS_KEY_ID="<Access Key ID>"`
    2. Add: `AWS_SECRET_ACCESS_KEY="<Secret Access Key>"`
    3. Add: `TF_VAR_terraform_statefile_bucket="k6haze-curator-tfstate"`
    4. Add: `TF_VAR_terraform_statefile_passphrase="<Generated Encrypt Key>"


## Create a GitHub App

This App will be able to construct secrets and secrets-workspaces via Infrastructure-as-Code.

It only has permissions to modify (take full ownership) of secrets within _this_ repository.

### Creating the App

 1. Go to [Github Apps](https://github.com/settings/apps) Page and click on "New Github App"
 2. Give it a meaningful name: `RK Curator Bot`
 3. The `Homepage URL` _can_ be set to a lower-case version of your "meaningful name" and convert spaces into dashes with a fix url
     1. So "RK Curator Bot" -> `rk-curator-bot`
     2. The Homepage URL would be [https://github.com/apps/rk-rosie-bot](https://github.com/apps/rk-curator-bot)
 4. Disable both:
     1. ` Expire user authorization tokens`
     2. Active Webhooks
 5. Permissions:
     1. `Environments`: `Read and Write`
     2. `Administator`: `Read and Write`  # needed to create environments
     2. `Contents`: `Read Only` # ???
     3. `Secrets`: `Read and Write`
     4. `Variables`: `Read and Write`
 6. Create
 7. On the next page, you'll need to capture:
     1. The `App ID`
     2. _(optional)_ The `Client ID` # USED THIS
 8. Scroll further down to `Generate a private key` and create a key
     3. Store the private pem key, somewhere safe

### Installing the App

 1. On the left side of the screen go to [Install](https://github.com/settings/apps/rk-curator-bot/installations).
 2. Choose your account and press "Install"
 3. Choose "Only Selected Repositories" and choose this repo then `Install`.

### Encrypting the Credentials

```bash
cp <path-to-private-pem-key> secrets/curator/BOT_APP_PRIVATE_KEY.sops.raw
sops -e --in-line secrets/curator/BOT_APP_PRIVATE_KEY.sops.raw
sops secrets/curator/bot.sops.env
# add:
# BOT_APP_ID="Client ID"
```

# Bootstrapping Tofu

Anytime you want to run tofu locally you'll need to modify your current shell to load the Age key _and_ decrypt the content to fetch the remote tfstate.

```bash
cd secrets
export SOPS_AGE_KEY_FILE=$(pwd)/secret.key
cd curator
set -a; source <(sops -d secrets/curator/tfstate.sops.env); set +a
set -a; source <(sops -d secrets/shared/cloudflare.sops.env); set +a
```

**WARNING**:

You'll need to create a PAT with: 
 * Environments: Read & Write (to add Environment Secrets)
 * Secrets: Read & Write (to add Secrets)
 * Administration: Read & Write (to create/destroy Environments)

Afterwards, it will behave as you'd expect

```bash
tofu init
GITHUB_TOKEN=gh-pat-xxxxxx tofu apply
```

Once the changes have been applied, then the Github Actions should be able to re-run the necessary changes.
