data "template_file" "boot-script" {
  template = <<EOF
#!/bin/bash -x
echo "################### postfix userdata start #######################"
yum install -y python3 cyrus-sasl 
pip3 install oci-cli
sed -i 's/inet_interfaces = localhost/inet_interfaces = all/' /etc/postfix/main.cf
echo "smtp_tls_security_level = encrypt" >> /etc/postfix/main.cf
echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> /etc/postfix/main.cf
echo "smtp_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
echo "myhostname = email-service.service.avaloq.com" >> /etc/postfix/main.cf
echo "relayhost = ${var.smtp_host}:${var.smtp_port}" >> /etc/postfix/main.cf
echo "${var.smtp_host}:${var.smtp_port} ${var.oci_email_userid}:${var.oci_email_password}" > /etc/postfix/sasl_passwd
chown root:root /etc/postfix/sasl_passwd && chmod 600 /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd
#postfix reload
systemctl stop firewalld
systemctl disable firewalld
echo "smtpd_sasl_path = smtpd" >> /etc/postfix/main.cf
echo "cyrus_sasl_config_path = /etc/sasl2/" >> /etc/postfix/main.cf
echo "smtpd_sasl_type = cyrus" >> /etc/postfix/main.cf
echo "smtpd_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "#Configuration managed by Terraform" > /etc/sasl2/pmcd.conf
echo "#Configuration managed by Terraform" > /etc/sasl2/smtpd.conf
echo "pwcheck_method: auxprop" >> /etc/sasl2/smtpd.conf
echo "auxprop_plugin: sasldb" >> /etc/sasl2/smtpd.conf
echo "mech_list: PLAIN LOGIN" >> /etc/sasl2/smtpd.conf
echo ${var.smtppasswd} |saslpasswd2 -c -u ${var.smtpdomain} -p ${var.smtpuser}
chown postfix:saslauth /etc/sasldb2
chmod 660 /etc/sasldb2
#firewall-cmd --add-service=smtp --permanent
systemctl start postfix
touch ~opc/userdata.`date +%s`.finish
echo "################### postfix userdata ends #######################" 
EOF
 }
