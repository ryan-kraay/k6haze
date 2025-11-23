# Purpose

This is a _manual_ step, which will create an S3 bucket (using [Cloudflare R2](https://www.cloudflare.com/developer-platform/products/r2/)).  This S3 bucket will then be used by other terraform projects to store our terraform state.

# Setup

_NOTE_:  These are unpolished references.  I'll need to rewrite and test it later.

1. In Cloudflare, create an Account Token and assign it to the target account.
2. Update [terraform.tfvars](./terraform.tfvars) and add your desired platforms.
3. Run: `tofu init` and `CLOUDFLARE_API_TOKEN=<token> tofu apply`
    1. The S3 buckets will be created, you _may_ store the `terraform.tfstate` (or not, depending on your requirements)
4. Create a _dedicated_ AWS Access Key/Secret for _each_ S3 bucket.
5. See the [github README](../github/README.md) for the next steps.
