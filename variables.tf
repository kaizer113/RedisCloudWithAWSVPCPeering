variable "aws_resources_name_prefix" {
  description = "Prefix used for AWS resource names."
  type        = string
  default     = "redis-peering"
}

variable "subscription_name" {
  description = "Redis Cloud Pro subscription name."
  type        = string
  default     = "redis-peering-pro-us-west-2"
}

variable "database_name" {
  description = "Redis Cloud database name."
  type        = string
  default     = "redis-peering-db"
}

variable "payment_method" {
  description = "Redis Cloud payment method. Use marketplace for Marketplace accounts, credit-card for card billing, or null for direct contracts that do not require a payment method."
  type        = string
  default     = "credit-card"

  validation {
    condition     = var.payment_method == null ? true : contains(["marketplace", "credit-card"], var.payment_method)
    error_message = "payment_method must be marketplace, credit-card, or null."
  }
}

variable "redis_deployment_cidr" {
  description = "Redis Cloud producer deployment CIDR. Must be a /24 and must not overlap the AWS VPC CIDR."
  type        = string
  default     = "192.168.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.redis_deployment_cidr)) && can(regex("/24$", var.redis_deployment_cidr))
    error_message = "redis_deployment_cidr must be a valid IPv4 /24 CIDR."
  }
}

variable "dataset_size_in_gb" {
  description = "Dataset size for the Redis database."
  type        = number
  default     = 25
}

variable "throughput_measurement_value" {
  description = "Database throughput in operations per second."
  type        = number
  default     = 25000
}

variable "replication" {
  description = "Whether database replication is enabled."
  type        = bool
  default     = false
}

variable "support_oss_cluster_api" {
  description = "Whether the Redis database should support the open-source Redis Cluster API."
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for both the existing VPC and the Redis Cloud subscription."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "Optional AWS shared config profile, for example an AWS SSO profile. Leave null to use the normal AWS credential chain."
  type        = string
  default     = null
}

variable "aws_vpc_id" {
  description = "The AWS consumer VPC ID to connect to Redis Cloud. This VPC must be in aws_region."
  type        = string
}

variable "aws_account_id" {
  description = "Expected 12-digit AWS account ID; prevents deploying to the wrong account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "enable_flex" {
  description = "Use Redis Flex (RAM and flash) instead of RAM-only storage. Changing this replaces the subscription."
  type        = bool
  default     = false
}

variable "ram_percentage" {
  description = "Percentage of the Flex dataset held in RAM. Used only when enable_flex is true."
  type        = number
  default     = 20

  validation {
    condition     = contains([10, 20, 30, 40, 50], var.ram_percentage)
    error_message = "ram_percentage must be 10, 20, 30, 40, or 50."
  }
}

variable "enable_public_endpoint" {
  description = "Enable the subscription public endpoint; database access remains restricted by source_ips."
  type        = bool
  default     = false
}

variable "additional_source_ips" {
  description = "Additional IPv4 CIDRs allowed to connect, such as a laptop public /32."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.additional_source_ips : can(cidrnetmask(cidr))])
    error_message = "additional_source_ips must contain valid IPv4 CIDRs."
  }
}
