##Common Vars########
aws_region                      = "us-east-1"
owner                           = "dxp"
env                             = "dev"
business_domain                 = "rajaparts"

##Elastic Search Vars######
instance_type                   = "t2.medium.elasticsearch"
instance_count                  = 3
ebs_volume_size                 = 10
create_iam_service_linked_role  = false
availability_zone_count         = 3
dedicated_master_count          = 3
dedicated_master_type           = "t2.medium.elasticsearch"
source_ips_api_access           = ["162.246.76.253" , "165.225.34.192","165.225.35.12","165.225.35.15", "165.225.35.17", "165.225.35.34", "165.225.35.38", "165.225.35.5", "165.225.217.33"]
source_ips_all_access           = ["52.201.33.9" , "34.203.18.70"]
encrypt_at_rest_enabled         = false
tags = {"owner" = "dxp", "resource" = "es" , "env" ="dev"}