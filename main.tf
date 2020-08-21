resource "aws_security_group" "default" {
  count       = var.enabled && var.vpc_enabled ? 1 : 0
  vpc_id      = var.vpc_id
  name        = var.domain_name
  description = "Allow inbound traffic from Security Groups and CIDRs. Allow all outbound traffic"
  tags        = var.tags
}

resource "aws_security_group_rule" "ingress_security_groups" {
  count                    = var.enabled && var.vpc_enabled ? length(var.security_groups) : 0
  description              = "Allow inbound traffic from Security Groups"
  type                     = "ingress"
  from_port                = var.ingress_port_range_start
  to_port                  = var.ingress_port_range_end
  protocol                 = "tcp"
  source_security_group_id = var.security_groups[count.index]
  security_group_id        = join("", aws_security_group.default.*.id)
}

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  count             = var.enabled && var.vpc_enabled && length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  description       = "Allow inbound traffic from CIDR blocks"
  type              = "ingress"
  from_port         = var.ingress_port_range_start
  to_port           = var.ingress_port_range_end
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = join("", aws_security_group.default.*.id)
}

resource "aws_security_group_rule" "egress" {
  count             = var.enabled && var.vpc_enabled ? 1 : 0
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.default.*.id)
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/5218
resource "aws_iam_service_linked_role" "default" {
  count            = var.enabled && var.create_iam_service_linked_role ? 1 : 0
  aws_service_name = "es.amazonaws.com"
  description      = "AWSServiceRoleForAmazonElasticsearchService Service-Linked Role"
}

resource "null_resource" "azs" {
  count = var.availability_zone_count > 1 ? 1 : 0
  triggers = {
    availability_zone_count = var.availability_zone_count
  }
}

resource "aws_elasticsearch_domain" "default" {
  count                 = var.enabled ? 1 : 0
  domain_name           = var.domain_name
  elasticsearch_version = var.elasticsearch_version

  advanced_options = var.advanced_options

  ebs_options {
    ebs_enabled = var.ebs_volume_size > 0 ? true : false
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
    iops        = var.ebs_iops
  }

  access_policies = data.aws_iam_policy_document.access.json

  encrypt_at_rest {
    enabled    = var.encrypt_at_rest_enabled
    kms_key_id = var.encrypt_at_rest_kms_key_id
  }

  domain_endpoint_options {
    enforce_https       = var.domain_endpoint_options_enforce_https
    tls_security_policy = var.domain_endpoint_options_tls_security_policy
  }

  cluster_config {
    instance_count           = var.instance_count
    instance_type            = var.instance_type
    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_count   = var.dedicated_master_count
    dedicated_master_type    = var.dedicated_master_type
    zone_awareness_enabled   = true

    dynamic "zone_awareness_config" {
      for_each = null_resource.azs[*].triggers
      content {
        availability_zone_count = zone_awareness_config.value.availability_zone_count
      }
    }
  }

  node_to_node_encryption {
    enabled = true
  }

  dynamic "vpc_options" {
    for_each = var.vpc_enabled ? [true] : []

    content {
      security_group_ids = [join("", aws_security_group.default.*.id)]
      subnet_ids         = var.subnet_ids
    }
  }

  snapshot_options {
    automated_snapshot_start_hour = var.automated_snapshot_start_hour
  }

  dynamic "cognito_options" {
    for_each = var.cognito_authentication_enabled ? [true] : []
    content {
      enabled          = true
      user_pool_id     = var.cognito_user_pool_id
      identity_pool_id = var.cognito_identity_pool_id
      role_arn         = var.cognito_iam_role_arn
    }
  }

  log_publishing_options {
    enabled                  = var.log_publishing_index_enabled
    log_type                 = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = var.log_publishing_index_cloudwatch_log_group_arn
  }

  log_publishing_options {
    enabled                  = var.log_publishing_search_enabled
    log_type                 = "SEARCH_SLOW_LOGS"
    cloudwatch_log_group_arn = var.log_publishing_search_cloudwatch_log_group_arn
  }

  log_publishing_options {
    enabled                  = var.log_publishing_application_enabled
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = var.log_publishing_application_cloudwatch_log_group_arn
  }

  tags = var.tags

  depends_on = [aws_iam_service_linked_role.default]
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "access" {
  statement {
    actions = [
      "es:*",
    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }

  statement {
    actions = [
      "es:*",
    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*",
    ]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_ips_all_access
    }
    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }

  statement {
    actions = [
      "es:ESHttpGet",
      "es:ESHttpPost"
    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*",
    ]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_ips_api_access
    }
    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }

  statement {
    actions = [
      "es:*",
    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }
}

module "domain_hostname" {
  source  = "git::https://github.com/cloudposse/terraform-aws-route53-cluster-hostname.git?ref=tags/0.3.0"
  enabled = var.enabled && var.dns_zone_id != "" ? true : false
  name    = var.elasticsearch_subdomain_name
  zone_id = var.dns_zone_id
  records = [join("", aws_elasticsearch_domain.default.*.endpoint)]
}

module "kibana_hostname" {
  source  = "git::https://github.com/cloudposse/terraform-aws-route53-cluster-hostname.git?ref=tags/0.3.0"
  enabled = var.enabled && var.dns_zone_id != "" ? true : false
  name    = var.kibana_subdomain_name
  ttl     = 60
  zone_id = var.dns_zone_id
  records = [join("", aws_elasticsearch_domain.default.*.endpoint)]
}
