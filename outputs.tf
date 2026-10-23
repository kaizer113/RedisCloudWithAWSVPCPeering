output "subscription_id" {
  value = rediscloud_subscription.pro.id
}

output "database_id" {
  value = rediscloud_subscription_database.database.db_id
}

output "private_endpoint" {
  value = rediscloud_subscription_database.database.private_endpoint
}

output "database_password" {
  value     = random_password.database.result
  sensitive = true
}

output "peering_id" {
  value = aws_vpc_peering_connection_accepter.redis.id
}

output "consumer_vpc_id" {
  value = data.aws_vpc.consumer.id
}

output "route_table_ids" {
  value = data.aws_route_tables.consumer.ids
}
