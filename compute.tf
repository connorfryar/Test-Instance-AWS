# locals {

#   user_data_args = {
#     # settings for certbot / TLS
#     DOMAIN  = var.domain
#     EMAIL   = var.email
#     KEYTYPE = var.keytype

#     # # https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/configuration
#     # # Application settings
#     # testinstance_hostname                  = var.testinstance_fqdn
#     # testinstance_operational_mode          = var.testinstance_operational_mode
#     # testinstance_capacity_concurrency      = var.testinstance_capacity_concurrency
#     # testinstance_capacity_cpu              = var.testinstance_capacity_cpu
#     # testinstance_capacity_memory           = var.testinstance_capacity_memory
#     # testinstance_license_reporting_opt_out = var.testinstance_license_reporting_opt_out
#     # testinstance_usage_reporting_opt_out   = var.testinstance_usage_reporting_opt_out
#     # testinstance_run_pipeline_driver       = "docker"
#     # testinstance_run_pipeline_image        = var.testinstance_run_pipeline_image == null ? "" : var.testinstance_run_pipeline_image
#     # testinstance_backup_restore_token      = ""
#     # testinstance_http_port                 = var.testinstance_http_port
#     # testinstance_https_port                = var.testinstance_https_port

#     # # Database settings
#     # testinstance_database_host       = "${aws_rds_cluster.testinstance.endpoint}:5432"
#     # testinstance_database_name       = aws_rds_cluster.testinstance.database_name
#     # testinstance_database_user       = var.testinstance_database_user
#     # testinstance_database_password   = data.aws_secretsmanager_secret_version.testinstance_database_password.secret_string
#     # testinstance_database_parameters = var.testinstance_database_parameters

#     # # Object storage settings
#     # testinstance_object_storage_type                                 = "s3"
#     # testinstance_object_storage_s3_bucket                            = aws_s3_bucket.testinstance.id
#     # testinstance_object_storage_s3_region                            = data.aws_region.current.name
#     # testinstance_object_storage_s3_endpoint                          = "" # check if needed for GovCloud
#     # testinstance_object_storage_s3_use_instance_profile              = var.testinstance_object_storage_s3_use_instance_profile
#     # testinstance_object_storage_s3_access_key_id                     = !var.testinstance_object_storage_s3_use_instance_profile ? var.testinstance_object_storage_s3_access_key_id : ""
#     # testinstance_object_storage_s3_secret_access_key                 = !var.testinstance_object_storage_s3_use_instance_profile ? var.testinstance_object_storage_s3_secret_access_key : ""
#     # testinstance_object_storage_s3_server_side_encryption            = var.s3_kms_key_arn == null ? "AES256" : "aws:kms"
#     # testinstance_object_storage_s3_server_side_encryption_kms_key_id = var.s3_kms_key_arn == null ? "" : var.s3_kms_key_arn

#     # # Redis settings
#     # testinstance_redis_host     = var.testinstance_operational_mode == "active-active" ? aws_elasticache_replication_group.redis_cluster[0].primary_endpoint_address : ""
#     # testinstance_redis_password = var.testinstance_operational_mode == "active-active" && var.testinstance_redis_password_secret_arn != null ? data.aws_secretsmanager_secret_version.testinstance_redis_password[0].secret_string : ""
#     # testinstance_redis_use_auth = var.testinstance_operational_mode == "active-active" && var.testinstance_redis_password_secret_arn != null ? true : false
#     # testinstance_redis_use_tls  = var.testinstance_operational_mode == "active-active" && var.redis_transit_encryption_enabled ? true : false

#     # # TLS settings
#     # testinstance_tls_cert_file      = "/etc/ssl/private/terraform-enterprise/cert.pem"
#     # testinstance_tls_key_file       = "/etc/ssl/private/terraform-enterprise/key.pem"
#     # testinstance_tls_ca_bundle_file = "/etc/ssl/private/terraform-enterprise/bundle.pem"
#     # testinstance_tls_enforce        = var.testinstance_tls_enforce
#     # testinstance_tls_ciphers        = "" # Leave blank to use the default ciphers
#     # testinstance_tls_version        = "" # Leave blank to use both TLS v1.2 and TLS v1.3

#     # # Observability settings
#     # testinstance_log_forwarding_enabled = var.testinstance_log_forwarding_enabled
#     # testinstance_metrics_enable         = var.testinstance_metrics_enable
#     # testinstance_metrics_http_port      = var.testinstance_metrics_http_port
#     # testinstance_metrics_https_port     = var.testinstance_metrics_https_port
#     # fluent_bit_rendered_config = local.fluent_bit_rendered_config

#     # # Vault settings
#     # testinstance_vault_use_external  = false
#     # testinstance_vault_disable_mlock = var.testinstance_vault_disable_mlock

#     # # Docker driver settings
#     # testinstance_run_pipeline_docker_network = var.testinstance_run_pipeline_docker_network == null ? "" : var.testinstance_run_pipeline_docker_network
#     # testinstance_hairpin_addressing          = var.testinstance_hairpin_addressing
#     # #testinstance_run_pipeline_docker_extra_hosts = "" // computed inside of testinstance_user_data script if `testinstance_hairpin_addressing` is `true` because EC2 private IP is used

#     # # Initial admin creation token settings
#     # testinstance_iact_token           = var.testinstance_iact_token == null ? "" : var.testinstance_iact_token
#     # testinstance_iact_subnets         = var.testinstance_iact_subnets == null ? "" : var.testinstance_iact_subnets
#     # testinstance_iact_time_limit      = var.testinstance_iact_time_limit
#     # testinstance_iact_trusted_proxies = var.testinstance_iact_trusted_proxies == null ? "" : var.testinstance_iact_trusted_proxies

#     # # Network settings
#     # http_proxy           = var.http_proxy != null ? var.http_proxy : ""
#     # https_proxy          = var.https_proxy != null ? var.https_proxy : ""
#     # no_proxy             = var.additional_no_proxy != null ? "${var.additional_no_proxy},${local.addl_no_proxy_base}" : local.addl_no_proxy_base
#     # testinstance_ipv6_enabled     = var.testinstance_ipv6_enabled
#     # testinstance_admin_https_port = var.testinstance_admin_https_port
#   }

#   testinstance_startup_script_tpl      = "${path.module}/userdata.sh.tpl"
#   user_data_template_rendered = templatefile(local.testinstance_startup_script_tpl, local.user_data_args)
# }