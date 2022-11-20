# Adapted default config for openSUSE MicroOS

#users:
# - root

disable_root: false
preserve_hostname: false
syslog_fix_perms: root:root
mount_default_fields: [~, ~, 'auto', 'defaults', '0', '2']

# The modules that run in the 'init' stage
cloud_init_modules:
 - migrator
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - disk_setup
 - mounts
 - set_hostname
 - update_hostname
 - update_etc_hosts
# - ca-certs
 - rsyslog
 - users-groups
 - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
 - locale
 - set-passwords
 - timezone
 - resolv_conf
 - ntp
 - zypper_add_repo
 - disable-ec2-metadata
 - runcmd

# The modules that run in the 'final' stage
cloud_final_modules:
# - package-update-upgrade-install
 - salt-minion
 - scripts-vendor
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - phone-home
 - final-message
 - power-state-change

# System and/or distro specific settings
system_info:
   distro: sles
   paths:
      cloud_dir: /var/lib/cloud/
      templates_dir: /etc/cloud/templates/
   ssh_svcname: sshd

datasource_list: [ ConfigDrive, None ]
datasource:
    ConfigDrive:
        dsmode: local
network: {config: disabled}
