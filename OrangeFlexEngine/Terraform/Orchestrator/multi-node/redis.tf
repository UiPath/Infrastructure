data "flexibleengine_dcs_az_v1" "az_1" {
         port = "8002"
        }
data "flexibleengine_dcs_product_v1" "product_1" {
          spec_code = "dcs.master_standby"
}

resource "flexibleengine_dcs_instance_v1" "uipath_redis" {
name  = "${var.elasticache}"
engine_version = "3.0"
password = "${var.redis_password}"
engine = "Redis"
capacity = 2
vpc_id =  "${flexibleengine_vpc_v1.uipath.id}"
security_group_id = "${var.default_sec_group}"

##Subnet ID is actually networkID so hack it with the instance ID
subnet_id = "${flexibleengine_nat_snat_rule_v2.snat_uipath.network_id}"

available_zones = ["eu-west-0a","eu-west-0b"]
product_id = "${data.flexibleengine_dcs_product_v1.product_1.id}"
save_days = 1
backup_type = "manual"
begin_at = "00:00-01:00"
period_type = "weekly"
backup_at = [1]
depends_on = ["flexibleengine_nat_snat_rule_v2.snat_uipath"]
        }
