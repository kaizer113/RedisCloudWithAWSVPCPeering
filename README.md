# Redis Cloud with AWS VPC Peering

Reusable Terraform to provision a Redis Cloud Pro subscription, one Redis database, and private connectivity to an **existing AWS VPC**. This repository contains provisioning configuration only.

## What Terraform creates

- A Redis Cloud Pro subscription in AWS and a password-protected database.
- A Redis Cloud VPC peering request, accepted in your AWS account.
- A route to the Redis deployment CIDR in **every route table in the selected VPC**.
- A generated 32-character database password, exposed as a sensitive Terraform output.

The existing VPC and subnets are not created or owned by this configuration. No compute instances or applications are provisioned.

Defaults: `us-west-2`, 25 GB dataset, 25,000 operations/sec, replication disabled, persistence disabled, and OSS Cluster API disabled. Public endpoint access is disabled by default; database source IPs default to the VPC's primary CIDR. TLS is not enabled by this configuration. These are demo defaults, not a production availability or durability configuration.

## Prerequisites

1. Terraform 1.5 or later. The committed provider lock file pins the resolved provider versions.
2. A Redis Cloud account eligible for Pro subscriptions, API access and secret keys, and an appropriate billing method.
3. AWS credentials with permission to read the VPC and route tables, accept and tag the peering connection, and create/delete routes. AWS CLI is useful for checking your account but is not required by Terraform.
4. An existing AWS VPC in the selected region. The Redis deployment CIDR must be an unused IPv4 `/24` that does not overlap **any** CIDR associated with that VPC. This configuration uses the VPC's primary CIDR for peering and database access; secondary CIDRs are outside its scope.
5. No conflicting routes to the Redis deployment CIDR in the VPC route tables. Review all affected route tables before applying.

Clients must already have network access to the selected VPC, with security groups and network ACLs allowing the database connection and return traffic. This configuration does not change those controls. A laptop without private network connectivity cannot use the private endpoint. For public access, set `enable_public_endpoint = true` and add the client public IP as a `/32` in `additional_source_ips`.

## Deploy

```sh
git clone https://github.com/kaizer113/RedisCloudWithAWSVPCPeering.git
cd RedisCloudWithAWSVPCPeering
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`: set your AWS account ID, VPC ID, region, Redis deployment CIDR, and billing method. Set `aws_profile` if using a named AWS profile; otherwise the AWS provider uses its normal credential chain. For SSO, sign in to that profile first. The expected account ID guards against accidentally targeting another account.

Provide Redis Cloud API credentials through environment variables. The following Bash/Zsh commands prompt without echoing the secrets or putting their values in shell history:

```sh
printf 'Redis Cloud access key: '
read -rs REDISCLOUD_ACCESS_KEY
printf '\nRedis Cloud secret key: '
read -rs REDISCLOUD_SECRET_KEY
printf '\n'
export REDISCLOUD_ACCESS_KEY REDISCLOUD_SECRET_KEY
```

Billing defaults to `credit-card`, using the account's payment-method lookup. Use `marketplace` for Marketplace billing or `null` for an eligible direct contract. Confirm the method with your Redis Cloud account configuration.

```sh
terraform init
terraform fmt -check
terraform validate
terraform plan -out=deployment.tfplan
terraform apply deployment.tfplan
terraform output
```

Applying provisions paid Redis Cloud resources. Review sizing and the planned route changes before applying. Subscription creation can take time; the configuration allows up to 60 minutes for creation.

## Outputs

```sh
terraform output -raw private_endpoint
terraform output -raw database_password
```

Other outputs provide the subscription ID, database ID, peering ID, consumer VPC ID, and affected route table IDs. The password command explicitly reveals the secret; avoid recording or sharing its output.

After deployment, verify that the peering is active and the selected route tables contain the Redis deployment route. A successful apply does not prove client connectivity; that depends on your existing network and client location.

## Configuration and tags

See [terraform.tfvars.example](terraform.tfvars.example) for common settings and [variables.tf](variables.tf) for all inputs. Both the Redis subscription and consumer VPC use `aws_region`.

The database and AWS peering connection receive `owner=lionel_giavelli` and `skip_deletion=yes`. Routes do not support tags. The Redis subscription uses Redis-managed cloud infrastructure; this configuration does not set infrastructure `resource_tags` on that managed cloud account.

## Redis Flex

Set `enable_flex = true` for a RAM-and-flash subscription. `dataset_size_in_gb` is the total dataset capacity across RAM and flash; `ram_percentage` defaults to 20 and accepts 10, 20, 30, 40, or 50. For example, 1 TB total capacity uses `dataset_size_in_gb = 1000` (decimal GB). Throughput is measured in Redis operations per second, not storage IOPS.

Changing `enable_flex` replaces the subscription. To create an additional Flex deployment while preserving a RAM-only deployment, use a separate checkout/state, distinct names, and a different non-overlapping Redis deployment CIDR. Do not apply that change to an existing deployment's state unless replacement is intended.

## State and credentials

Terraform uses local state by default. State and saved plans contain secrets, including the database password. They, local variable files, credentials and logs are excluded by `.gitignore`; keep them private. Retain the state so Terraform can manage and destroy resources. For shared operation, configure an access-controlled remote backend before deploying.

Each independent deployment needs its own state and variable values. Cloning this repository does not adopt existing resources; running it with fresh state provisions a new subscription and database.

## Cleanup

With the same credentials, variables and state used for deployment:

```sh
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

This deletes the managed database, subscription, peering and routes. It preserves the existing VPC and subnets. The `skip_deletion=yes` tag does not prevent explicit Terraform destruction.

## Provider documentation

- [Redis Cloud Terraform getting started](https://redis.io/docs/latest/integrate/terraform-provider-for-redis-cloud/get-started/)
- [Redis Cloud subscription](https://registry.terraform.io/providers/RedisLabs/rediscloud/latest/docs/resources/rediscloud_subscription)
- [Redis Cloud database](https://registry.terraform.io/providers/RedisLabs/rediscloud/latest/docs/resources/rediscloud_subscription_database)
- [Redis Cloud VPC peering](https://registry.terraform.io/providers/RedisLabs/rediscloud/latest/docs/resources/rediscloud_subscription_peering)

Adapted from [Redis Cloud with AWS Transit Gateway](https://github.com/kaizer113/RedisCloudWithAWSTransitGateway).
