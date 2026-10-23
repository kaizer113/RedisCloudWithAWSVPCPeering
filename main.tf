resource "random_password" "database" {
  length  = 32
  special = false
}

data "rediscloud_payment_method" "current" {
  count = var.payment_method == "credit-card" ? 1 : 0
}

resource "rediscloud_subscription" "pro" {
  name                   = var.subscription_name
  payment_method         = var.payment_method
  payment_method_id      = var.payment_method == "credit-card" ? data.rediscloud_payment_method.current[0].id : null
  memory_storage         = var.enable_flex ? "ram-and-flash" : "ram"
  public_endpoint_access = var.enable_public_endpoint

  cloud_provider {
    provider = "AWS"

    region {
      region                       = var.aws_region
      multiple_availability_zones  = false
      networking_deployment_cidr   = var.redis_deployment_cidr
      preferred_availability_zones = []
    }
  }

  creation_plan {
    dataset_size_in_gb           = var.dataset_size_in_gb
    ram_percentage               = var.enable_flex ? var.ram_percentage : null
    quantity                     = 1
    replication                  = var.replication
    support_oss_cluster_api      = var.support_oss_cluster_api
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = var.throughput_measurement_value
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

resource "rediscloud_subscription_database" "database" {
  subscription_id              = rediscloud_subscription.pro.id
  name                         = var.database_name
  dataset_size_in_gb           = var.dataset_size_in_gb
  ram_percentage               = var.enable_flex ? var.ram_percentage : null
  protocol                     = "redis"
  replication                  = var.replication
  support_oss_cluster_api      = var.support_oss_cluster_api
  data_persistence             = "none"
  throughput_measurement_by    = "operations-per-second"
  throughput_measurement_value = var.throughput_measurement_value
  password                     = random_password.database.result
  enable_default_user          = true
  source_ips                   = concat([data.aws_vpc.consumer.cidr_block], var.additional_source_ips)
  tags                         = local.tags

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

locals {
  tags = {
    owner         = "lionel_giavelli"
    skip_deletion = "yes"
  }
}

data "aws_vpc" "consumer" {
  id = var.aws_vpc_id
}

data "aws_route_tables" "consumer" {
  vpc_id = var.aws_vpc_id
}

resource "rediscloud_subscription_peering" "consumer" {
  subscription_id = rediscloud_subscription.pro.id
  region          = var.aws_region
  aws_account_id  = var.aws_account_id
  vpc_id          = data.aws_vpc.consumer.id
  vpc_cidr        = data.aws_vpc.consumer.cidr_block
}

resource "aws_vpc_peering_connection_accepter" "redis" {
  vpc_peering_connection_id = rediscloud_subscription_peering.consumer.aws_peering_id
  auto_accept               = true
  tags                      = { Name = var.aws_resources_name_prefix }
}

resource "aws_route" "redis" {
  for_each                  = toset(data.aws_route_tables.consumer.ids)
  route_table_id            = each.value
  destination_cidr_block    = var.redis_deployment_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.redis.id
}
