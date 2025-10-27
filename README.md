# Purpose

Testing Infrastructure is hard.  Where as testing software is a rather well understood concept, especially with concepts like [Test-Driven Development](https://en.wikipedia.org/wiki/Test-driven_development) this project will simply explore how much of TDD can be applied to infrastructure.

It's even harder when you're doing this as _cheap/free as possible_.  Sure, in a corporate environment or a homelab w/ VMs, if you want to test if the latest version of your CNI, you can spin-up a new VM, install the new CNI, and test it (manually or automatically).  **But**, if you've got a homelab w/ VMs or are in a corporate environment, you've probably got some _beefy_ machine or deep(er) pockets - _our goal is to be as cheap as possible_.

# The Current State

At the moment, the state of this project is unusable.  We have a very rough patch-work of PoC's, but nothing has been consolidated _nor_ tested.

# Goals

_...ordered by priority._

 * Create the cheapest (but not free) IPv6 _only_ Kubernetes Cluster
     * Current Total Cost:  less than $30.00 USD _per YEAR_ (~$2.50 / month).
     * [VPS Cost](https://billing.deluxhost.net/store/offer-i): 19 USD _per YEAR_. [referal link](https://billing.deluxhost.net/aff.php?aff=327)
     * _(optional)_ [Custom DNS](https://porkbun.com/tld/com): 11 USD _per YEAR_.
 * Follow TDD methodologies.  This means testing our infrastructure _before_ implementing the functionality.
     * The goal is to have a _high degree_ of certainy that our infrastructure exhibits an expected behavior.
 * Using [GitOps](https://about.gitlab.com/topics/gitops/) to create fully traceable, automated upgrades.
 * IPv6 **only**
     * This means, no NAT'ing and no IPv4.  Technically this means that _all_ Kubernetes Cluster IP Services, Pods, and LoadBalancers _are all publically accessible_, **but** we will use [Cilium](https://cilium.io/) to prevent unauthorized access.
 * Privacy/Security Centric
     * Although this repository and the knowledge is public, we will use encryption to try to high _sensative_ information.
     * The Cluster will also be secured, just as an exercise to find the balance between secure and usable.
 * Use this as a playground to explore tools, I'd never recommend using in production.
     * _... what's unstable today, could be an industry standard tomorrow._
 * Leverage AI for an assist:  AI (for better or for worse) is everywhere _and_ at the moment AI is _not_ as good for infrastructure as it _can be_ for writing code.
     * I'm curious to see if we have a extensive, manually created, test-suite - can we use AI to assist during the actual _implementation_?
     * The speculation is:  If we have confidence in our test-coverage and the AI assisted code (somehow) manages to pass our tests, it would be suitable for deployment.
     * Before AI, in my experience of using TDD:  Writing _detailed_ tests would take as long (if not longer) than writing the actual code.  _With AI_, I'm speculating that the time to write _detailed tests_ will take just as long, but I should gain sometime with AI assisting in the actual implementation.
 * [K.I.S.S.](https://en.wikipedia.org/wiki/KISS_principle):  Although our expectations are high, our collection of tooling used should be as low as possible.
 * _...and have fun learning and exploring._ This is just a passion/side project.  Don't expect too much.

What is **not** in scope:

 * No NAT64 Support:  Unfortunately, there are plenty of sites that still relying IPv4 (I'm looking at _you_ [GitHub](https://github.com/orgs/community/discussions/10539)) and using NAT64 as a way to allow IPv6 services to access IPv4 resources is "the way to do it".  However, our TODO is rather long, so this will be at the bottom of the TODO list.  Maybe the priority changes we high some "surprises".
 * No Multi-Node Support:  There's enough of a TODO list here.  However, once we reach a single node cluster which is stable/testable - supporting a multi-node setup **is high on the priority list** and should be _easy_, especially as we're _not using NATs_.
 * No High Availability:  As we are doing this _as cheap as possible_, HA usually requires quorum which increases your total cost.
     * _Maybe_, in a future iterate we can explore using [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/) as a _free_ LoadBalancing alternative.
 * No High Performance Cluster:  Again, being _as cheap as possible_, we're going to sacrifice performance if it means we save a few bucks and/or increase the security of our cluster.

# Technology Used

 * [Talos](https://www.talos.dev/):  It's a slick tool to _reliably_ rebuild kubernetes clusters from scratch.
 * [Cilium](https://cilium.io/):  A kubernetes based firewall, giving a way to protect our _publically exposed_ Kubernetes Pods from "the big scary internet".
 * [Flux](https://fluxcd.io/): More light-weight than [Argo CD](https://argo-cd.readthedocs.io/en/stable/) (which is important on a cheap VPS)
     * Flux also has built-in support for [SOPS](https://fluxcd.io/flux/guides/mozilla-sops/).  This means our "secrets" _can_ be encrypted in our git-repo and we don't need services like [External Secrets](https://external-secrets.io/latest/) consuming precious resources _in our cluster_.
 * [Jetify's Devbox](https://www.jetify.com/devbox):  A really easy way to bundle up 3rd party applications, create wrappers around them, and ensure that your testing pipelines are _identical_ to your development workflow.
 * [ShellSpec](https://shellspec.info/): Our TDD tool, it's a _Test Anything Platform_modelled after RSpec.  The (more popular) alternative appears to be [bats](https://bats-core.readthedocs.io/en/stable/writing-tests.html), however it lacks the "richness" in the JUnit output that ShellSpec posses (plus I really like the autogenerated RSpec style assert messages).
 * [Open Tofu](https://opentofu.org/): A fork of [Terraform](https://developer.hashicorp.com/terraform) used to install Talos and configure our Kubernetes cluster.
     * I've done a lot with Terraform, so let's sieze the opportunity and see what makes Open Tofu unique.
 * [Sigstore](https://www.sigstore.dev/): The self-proclaimed "Let's Encrypt of signing artifacts and git-commits".  It's similar to GitHub verified commits, but publically auditable.

# Requirements

**You will need:**

 * A Virtual-Private Server (VPS):
     * 8 GB of memory (~4 GB will be used to run Cilium + Flux + K8s)
     * A _dedicated static_ IPv6 subnet.  I've been assigned a `/64`.  However, you merely need enough ip-addresses for _all_ your pods, services, and loadbalancers.
     * A _single static_ IPv4 address.  My ISP currently provides only IPv4 (eyeroll), so some of these bootstrapping instructions assume IPv4.  This should be refactored as this system gains more stability.
 * A custom subdomain/domain
     * As we will be launching web services in our kubernetes cluster, it's very nice-to-have your own domain.  (plus, it can be used for other purposes like email, etc)
 * A [Cloudflare Always Free](https://www.cloudflare.com/plans/free/) Plan
     * We use it to manage our custom-domain's [DNS](https://www.cloudflare.com/application-services/products/dns/).
     * Also Cloudflare provides 10GB of [S3 storage](https://www.cloudflare.com/developer-platform/products/r2/), which is used to store the configuration for Open Tofu and host a few Talos Images (to help bootstrap our DeluxHost cluster).

