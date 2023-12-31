provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key      = var.private_key
  region           = var.region
}


data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}



data "oci_core_images" "oraclelinux" {
  compartment_id = var.compartment_id

  operating_system         = var.operating_system
  operating_system_version = var.operating_system_version

  # exclude GPU specific images
  filter {
    name   = "display_name"
    values = ["^([a-zA-z]+)-([a-zA-z]+)-([\\.0-9]+)-([\\.0-9-]+)$"]
    regex  = true
  }
}




resource "oci_core_public_ip" "CreatePublicIP" {
  compartment_id = var.compartment_id
  lifetime = var.public_ip_lifetime
  display_name = var.public_ip_display_name
  #BUG https://github.com/oracle/terraform-provider-oci/issues/1479
  private_ip_id = "ocid1.privateip.oc1.eu-zurich-1.ab5heljr2oksciz3nat7ba7tu7nn75ckxy54dx5ujn3kciv4yrbcmlsjz7rq"
   freeform_tags = {"Department"= "CSD"}
  //lifecycle {
  //  ignore_changes =    #to be moved on specific stack
  //}
}


resource "oci_core_virtual_network" "CreateVCN" {
  cidr_block     = var.vcn_cidr_block
  dns_label      = var.dns_label
  compartment_id = var.compartment_id
  display_name   = var.display_name
}

//Create NAT GW so private subnet will have access to Internet

resource "oci_core_nat_gateway" "CreateNatGateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.CreateVCN.id
  block_traffic  = var.nat_gateway_block_traffic
  display_name   = var.nat_gateway_display_name
}

//Create Internet Gateway for Public subnet

resource "oci_core_internet_gateway" "CreateIGW" {
  compartment_id = var.compartment_id
  enabled        = var.internet_gateway_enabled
  vcn_id         = oci_core_virtual_network.CreateVCN.id
  display_name   = var.internet_gateway_display_name
}

//Create two route tables - one public which has route to internet gateway and another one for private with a route to NAT GW

resource "oci_core_route_table" "CreatePublicRouteTable" {
  compartment_id = var.compartment_id

  route_rules {
    destination       = var.igw_route_cidr_block
    network_entity_id = oci_core_internet_gateway.CreateIGW.id
  }

  vcn_id       = oci_core_virtual_network.CreateVCN.id
  display_name = var.public_route_table_display_name
}

resource "oci_core_route_table" "CreatePrivateRouteTable" {
  compartment_id = var.compartment_id

  route_rules {
    destination       = var.natgw_route_cidr_block
    network_entity_id = oci_core_nat_gateway.CreateNatGateway.id
  }

  vcn_id       = oci_core_virtual_network.CreateVCN.id
  display_name = var.private_route_table_display_name
}

/*

Security List

*/

resource "oci_core_security_list" "CreatePublicSecurityList" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.CreateVCN.id
  display_name   = var.public_sl_display_name

  // Allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = var.egress_destination
    protocol    = var.tcp_protocol
  }

  // allow inbound ssh traffic from a specific port
  ingress_security_rules {
    protocol  = var.tcp_protocol         // tcp = 6
    source    = var.public_ssh_sl_source // Can be restricted for specific IP address
    stateless = var.rule_stateless

    tcp_options {
      // These values correspond to the destination port range.
      min = var.public_sl_ssh_tcp_port
      max = var.public_sl_ssh_tcp_port
    }
  }
  ingress_security_rules {
    protocol  = var.tcp_protocol          // tcp = 6
    source    = var.public_smtp_sl_source // Can be restricted for specific IP address
    stateless = var.rule_stateless

    tcp_options {
      // These values correspond to the destination port range.
      min = var.public_sl_smtp_tcp_port
      max = var.public_sl_smtp_tcp_port
    }
  }
  ingress_security_rules {
    protocol  = var.tcp_protocol   // tcp = 6
    //source    = var.vcn_cidr_block // open all ports for VCN CIDR and do not block subnet traffic 
    source = var.public_smtp_sl_source
    stateless = var.rule_stateless
  }
}

resource "oci_core_security_list" "CreatePrivateSecurityList" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.CreateVCN.id
  display_name   = var.private_sl_display_name

  // Allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = var.egress_destination
    protocol    = var.tcp_protocol
  }

  // allow inbound traffic from VCN
  ingress_security_rules {
    protocol  = var.tcp_protocol   // tcp = 6
    source    = var.vcn_cidr_block // VCN CIDR as allowed source and do not block subnet traffic 
    stateless = var.rule_stateless

    tcp_options {
      // These values correspond to the destination port range.
      min = var.private_sl_ssh_tcp_port
      max = var.private_sl_ssh_tcp_port
    }
  }
  ingress_security_rules {
    protocol  = var.tcp_protocol   // tcp = 6
    //source    = var.vcn_cidr_block // open all ports for VCN CIDR and do not block subnet traffic 
    source = var.public_smtp_sl_source
    stateless = var.rule_stateless

    tcp_options {
      // These values correspond to the destination port range.
      min = var.private_sl_smtp_tcp_port
      max = var.private_sl_smtp_tcp_port
    }
  }
}

// Create two subnets - one public where we will place a jump server and a another one where customer specific private resources are created

resource "oci_core_subnet" "CreatePublicSubnet" {
  availability_domain        = lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")
  cidr_block                 = cidrsubnet(var.vcn_cidr_block, 8, 0)
  display_name               = var.public_subnet_display_name
  dns_label                  = var.public_subnet_dns_label
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_virtual_network.CreateVCN.id
  security_list_ids          = [oci_core_security_list.CreatePublicSecurityList.id]
  route_table_id             = oci_core_route_table.CreatePublicRouteTable.id
  dhcp_options_id            = oci_core_virtual_network.CreateVCN.default_dhcp_options_id
  prohibit_public_ip_on_vnic = var.public_prohibit_public_ip_on_vnic
}

resource "oci_core_subnet" "CreatePublicSubnet2" {
  availability_domain        = lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")
  cidr_block                 = cidrsubnet(var.vcn_cidr_block, 8, 2)
  display_name               = var.public_subnet_display_name
  dns_label                  = var.public_subnet2_dns_label
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_virtual_network.CreateVCN.id
  security_list_ids          = [oci_core_security_list.CreatePublicSecurityList.id]
  route_table_id             = oci_core_route_table.CreatePublicRouteTable.id
  dhcp_options_id            = oci_core_virtual_network.CreateVCN.default_dhcp_options_id
  prohibit_public_ip_on_vnic = var.public_prohibit_public_ip_on_vnic
}

resource "oci_core_subnet" "CreatePrivateSubnet" {
  availability_domain        = lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")
  cidr_block                 = cidrsubnet(var.vcn_cidr_block, 8, 1)
  display_name               = var.private_subnet_display_name
  dns_label                  = var.private_subnet_dns_label
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_virtual_network.CreateVCN.id
  security_list_ids          = [oci_core_security_list.CreatePrivateSecurityList.id]
  route_table_id             = oci_core_route_table.CreatePrivateRouteTable.id
  dhcp_options_id            = oci_core_virtual_network.CreateVCN.default_dhcp_options_id
  prohibit_public_ip_on_vnic = var.private_prohibit_public_ip_on_vnic
}

// Create Load Balancer 

resource "oci_load_balancer" "CreateLoadBalancer" {
  shape          = var.lb_shape

  shape_details {
    minimum_bandwidth_in_mbps = var.lb_min_bandwidth_in_mbps 
    maximum_bandwidth_in_mbps = var.lb_max_bandwidth_in_mbps
  }

  compartment_id = var.compartment_id

  subnet_ids = [
    oci_core_subnet.CreatePublicSubnet.id,
    //oci_core_subnet.CreatePublicSubnet2.id,
  ]

	reserved_ips {

		#Optional
		id = oci_core_public_ip.CreatePublicIP.id
	}

  display_name = var.lb_name
  is_private   = var.lb_is_private
}

resource "oci_load_balancer_backend_set" "CreateLoadBalancerBackendSet" {
  name             = var.lb_be_name
  load_balancer_id = oci_load_balancer.CreateLoadBalancer.id
  policy           = var.lb_be_policy

  health_checker {
    port                = var.lb_be_health_checker_port
    protocol            = var.lb_be_health_checker_protocol
    response_body_regex = var.lb_be_health_checker_regex
    url_path            = var.lb_be_health_checker_urlpath
  }

  session_persistence_configuration {
    cookie_name      = var.lb_be_session_cookie
    disable_fallback = var.lb_be_session_fallback
  }
}

resource "oci_load_balancer_certificate" "load_balancer_email_cert" {
	certificate_name = var.certificate_name
	load_balancer_id = oci_load_balancer.CreateLoadBalancer.id
	//ca_certificate = var.certificate_ca
	//passphrase = var.certificate_passphrase
	private_key = var.certificate_private_key
	public_certificate = var.certificate_public
    lifecycle {
        create_before_destroy = true
    }

}

resource "oci_load_balancer_listener" "CreateListener" {
  load_balancer_id         = oci_load_balancer.CreateLoadBalancer.id
  name                     = var.lb_listener_name
  default_backend_set_name = oci_load_balancer_backend_set.CreateLoadBalancerBackendSet.name

  #hostname_names           = [oci_load_balancer_hostname.test_hostname1.name, oci_load_balancer_hostname.test_hostname2.name]
  port     = var.lb_listener_port
  protocol = var.lb_listener_protocol

  #rule_set_names           = [oci_load_balancer_rule_set.test_rule_set.name]

  connection_configuration {
    idle_timeout_in_seconds = var.lb_listener_connection_configuration_idle_timeout
  }
}

// CREATE LINUX INSTANCE IN THE PUBLIC SUBNET

resource "oci_core_instance" "CreateInstance" {
  availability_domain = lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")
  compartment_id      = var.compartment_id
  //shape               = var.instance_shape_name
 
  //shape_config { lookup(var.config) } #to be added with dynamyc group
  //shape = lookup(var.instance_shape_name, "shape", "VM.Standard.E2.2")
  shape = var.instance_shape
  shape_config {
    memory_in_gbs = var.instance_shape_config_memgb
    ocpus = var.instance_shape_ocpus
  }

  agent_config {
    is_monitoring_disabled = var.is_monitoring_disabled
  }
  

  source_details {
    source_id   = lookup(data.oci_core_images.oraclelinux.images[0], "id")
    source_type = var.source_type
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.CreatePublicSubnet.id
    assign_public_ip = var.assign_public_ip
    hostname_label   = var.instance_create_vnic_details_hostname_label
  }

  display_name = var.instance_display_name

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = "${base64encode(data.template_file.boot-script.rendered)}"
    }

  //subnet_id = oci_core_subnet.CreatePublicSubnet.id
}
resource "oci_core_instance_configuration" "CreateInstanceConfiguration" {
  compartment_id = var.compartment_id
  display_name   = var.instance_configuration_name

  instance_details {
    instance_type = var.instance_configuration_type

    launch_details {
      compartment_id = var.compartment_id
      shape = var.instance_shape
      shape_config {
        memory_in_gbs = var.instance_shape_config_memgb
        ocpus = var.instance_shape_ocpus
  }
      //shape_config = var.instance_shape_config
      display_name   = var.instance_configuration_name
      agent_config {
      is_monitoring_disabled = var.is_monitoring_disabled
      }

      create_vnic_details {
        assign_public_ip       = var.instance_configuration_vnic_details_assign_public_ip
        display_name           = var.instance_configuration_vnic_details_name
        skip_source_dest_check = var.instance_configuration_vcnic_skip_source_dest_check
      }

      metadata = {
        ssh_authorized_keys = var.ssh_public_key
        //user_data           = base64encode(var.user-data)
        //user_data = base64encode(local.bootscript)
        user_data = "${base64encode(data.template_file.boot-script.rendered)}"
      }

      source_details {
        source_type = var.instance_configuration_source_details_source_type
        image_id    = lookup(data.oci_core_images.oraclelinux.images[1], "id")
      }
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_core_instance_pool" "CreateInstancePool" {
  compartment_id            = var.compartment_id
  instance_configuration_id = oci_core_instance_configuration.CreateInstanceConfiguration.id
  size                      = var.instance_pool_size
  state                     = var.instance_pool_state
  display_name              = var.instance_pool_name

  placement_configurations {
    availability_domain = lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")
    primary_subnet_id   = oci_core_subnet.CreatePrivateSubnet.id
  }

  load_balancers {
    #Required
    backend_set_name = oci_load_balancer_backend_set.CreateLoadBalancerBackendSet.name
    load_balancer_id = oci_load_balancer.CreateLoadBalancer.id
    port             = var.instance_pool_load_balancers_port
    vnic_selection   = var.instance_pool_load_balancers_vnic_selection
  }
  //depends_on = ["oci_core_instance_configuration.CreateInstanceConfiguration"]
}

resource "oci_autoscaling_auto_scaling_configuration" "CreateAutoScalingConfiguration" {
  compartment_id       = var.compartment_id
  cool_down_in_seconds = var.autoscaling_cooldown_in_seconds
  display_name         = var.autoscaling_name
  is_enabled           = var.autoscaling_is_enabled

  policies {
    capacity {
      initial = var.autoscaling_policies_initial
      max     = var.autoscaling_policies_max
      min     = var.autoscaling_policies_min
    }

    display_name = var.autoscaling_policy_name
    policy_type  = var.autoscaling_type

    rules {
      action {
        type  = var.autoscaling_rules_action_type_out
        value = var.autoscaling_rules_action_value_out
      }

      display_name = var.autoscaling_rules_name_out

      metric {
        metric_type = var.autoscaling_rules_metric_type_out

        threshold {
          operator = var.autoscaling_rules_metric_threshold_operator_out
          value    = var.autoscaling_rules_metric_threshold_value_out
        }
      }
    }

    rules {
      action {
        type  = var.autoscaling_rules_action_type_in
        value = var.autoscaling_rules_action_value_in
      }

      display_name = var.autoscaling_rules_name_in

      metric {
        metric_type = var.autoscaling_rules_metric_type_in

        threshold {
          operator = var.autoscaling_rules_metric_threshold_operator_in
          value    = var.autoscaling_rules_metric_threshold_value_in
        }
      }
    }
  }

  auto_scaling_resources {
    id   = oci_core_instance_pool.CreateInstancePool.id
    type = var.autoscaling_resources_type
  }
  
}


resource "oci_ons_notification_topic" "CreateNotificationTopic" {
  #Required
  compartment_id = var.compartment_id
  name           = var.notification_topic_name
  #Optional
  description = var.notification_topic_description

}

resource "oci_events_rule" "CreateEventsRule" {
  #Required
  actions {
    #Required
    actions {
      #Required
      action_type = var.rule_actions_actions_action_type
      is_enabled  = var.rule_actions_actions_is_enabled

      #Optional
      description = var.rule_actions_actions_description
      topic_id    = oci_ons_notification_topic.CreateNotificationTopic.id
    }
  }
  compartment_id = var.compartment_id
  condition      = var.rule_condition
  display_name   = var.rule_display_name
  is_enabled     = var.rule_is_enabled
  #Optional
  description = "${var.rule_description}"
}
