provider "alicloud" {
  region = "cn-shanghai"
}

resource "random_integer" "default" {
  max = 99999
  min = 10000
}

resource "alicloud_ssl_certificates_service_certificate" "default" {
  certificate_name = "tf_certificate_${random_integer.default.result}"
  cert             = var.ssl_cert
  key              = var.ssl_key
}

data "alicloud_alb_zones" "default" {}

resource "alicloud_vpc" "default" {
  vpc_name   = var.vpc_name
  cidr_block = var.vpc_cidr_block
}

resource "alicloud_vswitch" "vswitch_1" {
  vpc_id       = alicloud_vpc.default.id
  cidr_block   = cidrsubnet(alicloud_vpc.default.cidr_block, 8, 2)
  zone_id      = data.alicloud_alb_zones.default.zones[3].id
  vswitch_name = var.vswitch_name_1
}

resource "alicloud_vswitch" "vswitch_2" {
  vpc_id       = alicloud_vpc.default.id
  cidr_block   = cidrsubnet(alicloud_vpc.default.cidr_block, 8, 4)
  zone_id      = data.alicloud_alb_zones.default.zones[4].id
  vswitch_name = var.vswitch_name_2
}

resource "alicloud_log_project" "default" {
  project_name = "${var.log_project_name}-${random_integer.default.result}"
  description  = "created by terraform"
}

resource "alicloud_log_store" "default" {
  project_name          = alicloud_log_project.default.project_name
  logstore_name         = "${var.log_store_name}-${random_integer.default.result}"
  shard_count           = 3
  auto_split            = true
  max_split_shard_count = 60
  append_meta           = true
}

module "example" {
  create                 = true
  source                 = "../.."
  vpc_id                 = alicloud_vpc.default.id
  address_type           = "Internet"
  address_allocated_mode = "Fixed"
  load_balancer_name     = "tf_alb_name"
  load_balancer_edition  = "Basic"
  zone_mappings = [
    { vswitch_id = alicloud_vswitch.vswitch_1.id, zone_id = alicloud_vswitch.vswitch_1.zone_id },
    { vswitch_id = alicloud_vswitch.vswitch_2.id, zone_id = alicloud_vswitch.vswitch_2.zone_id }
  ]
  access_log_config = [
    { log_project = alicloud_log_project.default.name, log_store = alicloud_log_store.default.name }
  ]
  acl_name             = "tf_acl_name"
  server_group_name    = "acl_server_group_name"
  certificate_id       = join("", [alicloud_ssl_certificates_service_certificate.default.id, "-cn-hangzhou"])
  listener_port        = 80
  listener_description = "CreatedByTerraform"
}