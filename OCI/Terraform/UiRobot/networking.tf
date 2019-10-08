
# Network
data "oci_identity_availability_domain" "ad" {
  compartment_id = "${var.tenancy_ocid}"
  ad_number      = 1
}

resource "oci_core_vcn" "uirobot_vcn" {
  cidr_block     = "${var.vcn_cidr}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.prefix_label}VCN"
  dns_label      = "${var.vcn_dns_label}"
}

resource "oci_core_internet_gateway" "uirobot_internet_gateway" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.prefix_label}InternetGateway"
  vcn_id         = "${oci_core_vcn.uirobot_vcn.id}"
}

resource "oci_core_route_table" "uirobot_security_list" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_vcn.uirobot_vcn.id}"
  display_name   = "${var.prefix_label}RouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.uirobot_internet_gateway.id}"
  }
}

# https://docs.cloud.oracle.com/iaas/Content/Compute/Tasks/accessinginstance.htm#one
resource "oci_core_security_list" "uirobot_security_list" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_vcn.uirobot_vcn.id}"
  display_name   = "${var.prefix_label}SecurityList"

  # allow inbound remote desktop traffic
  ingress_security_rules {
    protocol  = "6"         # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      # These values correspond to the destination port range.
      min = 3389
      max = 3389
    }
  }

  # allow inbound winrm traffic
  ingress_security_rules {
    protocol  = "6"         # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      # These values correspond to the destination port range.
      min = 5985
      max = 5986
    }
  }

  # allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

resource "oci_core_subnet" "uirobot_subnet" {
  availability_domain = "${data.oci_identity_availability_domain.ad.name}"
  cidr_block          = "${var.subnet_cidr}"
  display_name        = "${var.prefix_label}Subnet"
  dns_label           = "${var.subnet_dns_label}"
  security_list_ids   = ["${oci_core_security_list.uirobot_security_list.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_vcn.uirobot_vcn.id}"
  route_table_id      = "${oci_core_route_table.uirobot_security_list.id}"
  dhcp_options_id     = "${oci_core_vcn.uirobot_vcn.default_dhcp_options_id}"
}