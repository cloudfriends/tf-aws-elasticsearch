locals {
  es_domain_name               = "es-${var.owner}-${var.env}-${var.business_domain}"
  kibana_subdomain_name        = "kibana-${var.owner}-${var.env}-${var.business_domain}"
}

module "elasticsearch" {
  source                         = "../../"
  domain_name                    = local.es_domain_name
  elasticsearch_subdomain_name   = local.es_domain_name
  kibana_subdomain_name          = local.kibana_subdomain_name
  ebs_volume_size                = var.ebs_volume_size
  availability_zone_count        = var.availability_zone_count
  instance_type                  = var.instance_type
  instance_count                 = var.instance_count
  dedicated_master_count          = var.dedicated_master_count
  dedicated_master_type           = var.dedicated_master_type
  source_ips_api_access           = var.source_ips_api_access
  source_ips_all_access           = var.source_ips_all_access
  encrypt_at_rest_enabled         = var.encrypt_at_rest_enabled
  create_iam_service_linked_role  = var.create_iam_service_linked_role
  tags                            = var.tags
}

module "store_write" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=tags/0.3.0"
  parameter_write = [{
  name            = "/dev/esurl"
  value           = format("%s%s", "https://",module.elasticsearch.domain_endpoint)
  type            = "String"
  overwrite       = "true"
  description     = "Elasticsearch URL"
  }]

  tags = {
      CreatedBy = "Terraform"
  }
}