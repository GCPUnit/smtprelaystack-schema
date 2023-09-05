variable "tenancy_ocid" {
  type = string
}     // Your tenancy's OCID
variable "user_ocid" {
  type = string
  //sensitive   = true
  //nullable = false
}        // Your user's OCID
variable "fingerprint" {
  type = string
  //sensitive   = true
  //nullable = false
}      // Fingerprint for the user key, can be found under user in console
variable "private_key" {
  type = string
  //sensitive   = true
  //nullable = false
} // Where your private key is located on the server you are running these scripts
variable "region" {
  type = string
  //nullable = false
}           // Which region is used in OCI eg. eu-frankfurt-1 

// ORACLE LINUX VERSION AND OS NAME

variable "operating_system" {
  type = string
} // Name for the OS

variable "operating_system_version" {
  type = string
  
} // OS Version

// COMPARTMENT VARIABLES
variable "compartment_id" {
  type = string
} // compartment OCID

//variable "compartment_description" {
//  
//} // Description for the compartment

variable "public_ip_lifetime" {
  type = string
  
}

variable "public_ip_display_name" {
  type = string
  
}

// VCN VARIABLES
variable "vcn_cidr_block" {
  type = string
  
} // Define the CIDR block for your OCI cloud

variable "vcn_display_name" {
  type = string
  
} // VCN Name

variable "vcn_dns_label" {
  type = string
  
} // DNS Label for VCN

// NAT GW VARIABLES
variable "nat_gateway_display_name" {
  type = string
  
} // Name for the NAT GW

variable "nat_gateway_block_traffic" {
  type = bool
  
} // Is NAT GW active or not

// INTERNET GW VARIABLES

variable "internet_gateway_display_name" {
  type = string
  
} // Name for the IGW

variable "internet_gateway_enabled" {
  type = bool
  
} // Is IGW enabled or not

// PUBLIC AND PRIVATE ROUTETABLE VARIABLES

variable "public_route_table_display_name" {
  type = string
  
} // Name for the public routetable

variable "private_route_table_display_name" {
  type = string
  
} // Name for the private routetable

variable "igw_route_cidr_block" {
  type = string
  
}

variable "natgw_route_cidr_block" {
  type = string
  
}

// PUBLIC AND PRIVATE SECURITYLIST VARIABLES

variable "public_sl_display_name" {
  type = string
  
} // Name for the public securitylist

variable "private_sl_display_name" {
  type = string
  
} // Name for the private securitylist

variable "egress_destination" {
  type = string
  
} // Outside traffic is allowed

variable "tcp_protocol" {
  type = number
  
} // 6 for TCP traffic

variable "public_ssh_sl_source" {
  type = string
  
}

variable "public_smtp_sl_source" {
  type = string
  
}

variable "rule_stateless" {
  type = bool
  
} // All rules are stateful by 

variable "public_sl_ssh_tcp_port" {
  type = number
  
} // Open port 22 for SSH access

variable "private_sl_ssh_tcp_port" {
  type = number
  
} // Open port 22 for SSH access

variable "private_sl_smtp_tcp_port" {
  type = number
  
} // Open port 25 for SMTP

variable "public_sl_smtp_tcp_port" {
  type = number
  
} // Open port 25 for SMTP

// PUBLIC AND PRIVATE SUBNET VARIABLES
variable "public_subnet_display_name" {
  type = string
  
} // Name for public subnet

variable "private_subnet_display_name" {
  type = string
  
} // Name for private subnet

variable "public_subnet_dns_label" {
  type = string
  
} // DNS Label for public subnet 1

variable "public_subnet2_dns_label" {
  type = string
  
} // DNS Label for public subnet 2

variable "private_subnet_dns_label" {
  type = string
  
} // DNS label for private subnet

variable "public_prohibit_public_ip_on_vnic" {
  type = bool
  
} // Can instances in public subnet get public IP

variable "private_prohibit_public_ip_on_vnic" {
  type = bool
  
} // Can instances in private subnet get public IP

// INSTANCE VARIABLES

//variable "instance_shape_name" {
//  
//  description = "The shape of instances."
  //
//}  
//variable "instance_shape_config" {
//  
//}
variable "instance_shape" {
  type = string
  description = "The shape of instances"
  
}

variable "instance_shape_config_memgb" {
  type = number
  
}

variable "instance_shape_ocpus" {
  type = number
  
  
}
variable "source_type" {
  type = string
  
} // What type the image source is

variable "assign_public_ip" {
  type = bool
  
} // This is server in public subnet it will have a public IP
variable "instance_display_name" {
  type = string
  
} // Name for the instance

variable "instance_create_vnic_details_hostname_label" {
  type = string
  
}

variable "is_monitoring_disabled" {
  type = bool
  
}

variable "ssh_public_key" {
  type = string
  
}

// INSTANCE POOL VARIABLES

variable "instance_pool_load_balancers_port" {
  type = number
  
} // What port load balancer listener is on

variable "instance_pool_load_balancers_vnic_selection" {
  type = string
  
} // Use primary VCNIC


variable "smtp_port" {
  type = number
  
}

variable "smtp_host" {
  type = string
  
}

variable "oci_email_userid" {
  type = string
  
}

variable "oci_email_password" {
  type = string
  
  
}
// LOAD BALANCER VARIABLES

variable "lb_shape" {
  type = string
  
}

variable "lb_min_bandwidth_in_mbps" {
  type = number
  
}

variable "lb_max_bandwidth_in_mbps" {
  type = number
  
}

variable "lb_name" {
  type = string
  
}

variable "lb_is_private" {
  type = bool
  
}

variable "lb_be_name" {
  type = string
  
}

variable "lb_be_policy" {
  type = string
  
}

variable "lb_be_health_checker_port" {
  type = number
  
}

variable "lb_be_health_checker_protocol" {
  type = string
  
}

variable "lb_be_health_checker_regex" {
  type = string
  
}

variable "lb_be_health_checker_urlpath" {
  type = string
  
}

variable "lb_be_session_cookie" {
  type = string
  
}

variable "lb_be_session_fallback" {
  type = bool
  
}

variable "lb_listener_name" {
  type = string
  
}

variable "lb_listener_port" {
  type = number
  
}

variable "lb_listener_protocol" {
  type = string
  
}

variable "lb_listener_connection_configuration_idle_timeout" {
  type = number
  
}

// INSTANCE CONFIGURATION VARIABLES

variable "instance_configuration_name" {
  type = string
  
}

variable "instance_configuration_type" {
  type = string
  
}

variable "instance_configuration_launch_details_name" {
  type = string
  
}

variable "instance_configuration_vnic_details_assign_public_ip" {
  type = bool
  
}

variable "instance_configuration_vnic_details_name" {
  type = string
  
}

variable "instance_configuration_vcnic_skip_source_dest_check" {
  type = bool
  
}

variable "instance_configuration_source_details_source_type" {
  type = string
  
}

// INSTANCE POOL VARIABLES

variable "instance_pool_size" {
  type = number
  
}

variable "instance_pool_state" {
  type = string
  
}

variable "instance_pool_name" {
  type = string
  
}

// AUTOSCALING VARIABLES
variable "autoscaling_cooldown_in_seconds" {
  type = number
  
}

variable "autoscaling_name" {
  type = string
  
}

variable "autoscaling_is_enabled" {
  type = bool
  
}

variable "autoscaling_policies_initial" {
  type = number
  
}

variable "autoscaling_policies_max" {
  type = number
  
}

variable "autoscaling_policies_min" {
  type = number
  
}

variable "autoscaling_policy_name" {
  type = string
  
}

variable "autoscaling_type" {
  type = string
  
}

variable "autoscaling_rules_action_type_out" {
  type = string
  
}

variable "autoscaling_rules_action_value_out" {
  type = number
  
}

variable "autoscaling_rules_name_out" {
  type = string
  
}

variable "autoscaling_rules_metric_type_out" {
  type = string
  
}

variable "autoscaling_rules_metric_threshold_operator_out" {
  type = string
  
}

variable "autoscaling_rules_metric_threshold_value_out" {
  type = number
  
}

variable "autoscaling_rules_action_type_in" {
  type = string
  
}

variable "autoscaling_rules_action_value_in" {
  type = number
  
}

variable "autoscaling_rules_name_in" {
  type = string
  
}

variable "autoscaling_rules_metric_type_in" {
  type = string
  
}

variable "autoscaling_rules_metric_threshold_operator_in" {
  type = string
  
}

variable "autoscaling_rules_metric_threshold_value_in" {
  type = number
  
}

variable "autoscaling_resources_type" {
  type = string
  
}

// Variables for Notification Topic and Subscription

variable "notification_topic_name" {
  type = string
  
}
variable "notification_topic_description" {
  type = string
  
}

// Variables for Events Rule

variable "rule_actions_actions_action_type" {
  type = string
  
}

variable "rule_actions_actions_is_enabled" {
  type = bool
  
}

variable "rule_actions_actions_description" {
  type = string
  
}

variable "rule_condition" {
  type = string
  
}

variable "rule_display_name" {
  type = string
  
}

variable "rule_is_enabled" {
  type = bool
  
}

variable "rule_description" {
  type = string
  
}

variable "certificate_name" {
  type = string
  
}

variable "certificate_passphrase" {
  type = string
  
  ////sensitive = true
}

variable "certificate_ca" {
  type = string
  
  
}
variable "certificate_private_key" {
  type = string
   ////sensitive = true
   
}

variable "certificate_public" {
  type = string
    
}

variable "smtppasswd" {
  type = string

    
}

variable "smtpuser" {
  type = string

    
}

variable "smtpdomain" {
  type = string

    
  
}