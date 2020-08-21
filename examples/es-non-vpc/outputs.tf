output "arn" {
  value = module.elasticsearch.domain_arn
}

output "domain_name" {
  value = module.elasticsearch.domain_name
}

output "domain_id" {
  value = module.elasticsearch.domain_id
}

output "domain_endpoint" {
  value = format("%s%s", "https://",module.elasticsearch.domain_endpoint)
}

output "kibana_endpoint" {
  value = format("%s%s", "https://",module.elasticsearch.kibana_endpoint)
}
