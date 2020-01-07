# Outputs
# output "username" {
#   value = ["${data.oci_core_instance_credentials.instance_credentials.*.username}"]
# }
output "instances_public_ip" {
  value = ["${oci_core_instance.uirobot_instance.*.public_ip}"]
}
# output "instances_private_ip" {
#   value = ["${oci_core_instance.uirobot_instance.*.private_ip}"]
# }