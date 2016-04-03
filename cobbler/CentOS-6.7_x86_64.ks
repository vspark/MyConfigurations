# kickstart template for Fedora 8 and later.
# (includes %end blocks)
# do not use with earlier distros

#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
bootloader --location=mbr --append=" biosdevname=0"
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --enabled
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot
#Root password
rootpw --iscrypted $default_password_crypted
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  Asia/Shanghai
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr
# Allow anaconda to partition the system as needed
# %include /tmp/partition.ks
autopart

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

#%packages
%packages --nobase
@core
@server-policy
wget
vim
rsyslog
sysstat
ntpdate
net-snmp
lrzsz
rsync
telnet
traceroute
zip
unzip
lsof
dmidecode
sysstat
openssh-clients
tcpdump
aide
$SNIPPET('func_install_if_enabled')
%end


%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')

### Repo Setup ###
##rm -f /etc/yum.repos.d/CentOS*
#yum -y install yum-plugin-priorities
#sed -i "s/enabled = 1/enabled = 0/"  /etc/yum/pluginconf.d/priorities.conf

#2.Set the character encoding to zh_CN.UTF-8
#3.Set the sshConfig banned root login
/bin/cp -i /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
#sed -i 's%#PermitRootLogin yes%PermitRootLogin no%' /etc/ssh/sshd_config
sed -i 's%#PermitEmptyPasswords no%PermitEmptyPasswords no%' /etc/ssh/sshd_config
sed -i 's%#UseDNS yes%UseDNS no' /etc/ssh/sshd_config
sed -i 's%#GSSAPIAuthentication yes%GSSAPIAuthentication no%' /etc/ssh/sshd_config
sed -i 's%#ClientAliveInterval 0%ClientAliveInterval 600%' /etc/ssh/sshd_config
sed -i 's%#ClientAliveCountMax 3%ClientAliveCountMax 0%' /etc/ssh/sshd_config
sed -i 's%#IgnoreRhosts yes%IgnoreRhosts yes%' /etc/ssh/sshd_config
sed -i 's%#HostbasedAuthentication no%HostbasedAuthentication no%' /etc/ssh/sshd_config
sed -i 's%#PermitEmptyPasswords no%PermitEmptyPasswords no%' /etc/ssh/sshd_config
sed -i 's%#LogLevel INFO%LogLevel INFO%' /etc/ssh/sshd_config

#disable user root ssh \ set IP white list
#sed -i 's%#PermitRootLogin yes%PermitRootLogin no%' /etc/ssh/sshd_config
#sed -i 's%#ListenAddress 0.0.0.0%ListenAddress 192.168.250.xx%' /etc/ssh/sshd_config

#restart sshd
/etc/init.d/sshd reload

#4.Disable ctrl+alt+del three key to reboot system
mv /etc/init/control-alt-delete.conf /etc/init/control-alt-delete.conf.bak

#add groups
groupadd -g 500 appuser
#groupadd -g 600 admin
#add users passwd is 'Zh123!@#'
useradd  -g appuser -u 500 -p '$1$random-p$ulXkdG90bOmqSQUHvrLHV/' appuser
#useradd  -g admin   -u 600 -p '$1$random-p$ulXkdG90bOmqSQUHvrLHV/' admin
#permit admin and appuser su to root
#usermod -G wheel admin
#usermod -G wheel appuser
#group wheel can su to root and no password
sed -i '/pam_wheel\.so trust use_uid/s/^#//g' /etc/pam.d/su
##group wheel can su to root but password needed
#sed -i '/pam_wheel.so use_uid/s/^#//g' /etc/pam.d/su

#6.Adjust the number of open files
/bin/cp -i /etc/security/limits.conf /etc/security/limits.conf.bak
sed -i '/# End of file/i\*\t\t-\tnofile\t\t65535' /etc/security/limits.conf
sed -i 's/1024/65535/' /etc/security/limits.d/90-nproc.conf
ulimit -HSn 65535

#7 set ntp
echo "192.168.100.12 ntp" >> /etc/hosts
/usr/sbin/ntpdate ntp
echo "*/10 * * * * /usr/sbin/ntpdate ntp | logger -t NTP;/usr/sbin/hwclock -w" >>/var/spool/cron/root

#8 Set Java Enveroment

#9 Optimization of system kernel
/bin/cp -i /etc/sysctl.conf /etc/sysctl.conf.bak
cat>>/etc/sysctl.conf<<EOF
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 87380 16777216
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
EOF
/sbin/sysctl -p

#10 Prohibit the use of IPV6
/bin/cp -i /etc/modprobe.d/dist.conf /etc/modprobe.d/dist.conf.bak
echo "alias net-pf-10 off" >> /etc/modprobe.d/dist.conf
echo "options ipv6 disable=1" >> /etc/modprobe.d/dist.conf

#11 delete unused users and grups
for i in lp sync shutdown halt news uucp operator games gopher
do
userdel $i
done
for i in lp sync shutdown halt news uucp operator games gopher
do
groupdel $i
done

#12 set users password policy
/bin/cp -i /etc/login.defs /etc/login.defs.bak
sed -i '/PASS_MIN_LEN/s/5/12/g' /etc/login.defs
sed -i '/PASS_MAX_DAYS/s/99999/90/g' /etc/login.defs
/bin/cp -i /etc/profile /etc/profile.bak
sed -i 's%password    requisite     pam_cracklib\.so try_first_pass retry=3 type=%password    requisite     pam_cracklib\.so try_first_pass retry=3 minlen=12 dcredit=1 ucredit=1 lcredit=1 ocredit=1%' /etc/pam.d/system-auth
echo 'auth required pam_tally2.so onerr=fail deny=5 unlock_time=300' >> /etc/pam.d/system-auth
echo 'TMOUT=600' >> /etc/profile

#15 Configure the scripts right(750) in rc.d directory
#chmod -R 750 /etc/rc.d/init.d/*
#chmod 755 /bin/su
#chmod 664 /var/log/wtmp
#chattr +a /var/log/messages


#18 vim setting
sed -i "8 s/^/alias vi='vim'/" /root/.bashrc
echo 'syntax on' > /root/.vimrc

#19 history setting
sed -i 's%HISTSIZE=1000%HISTSIZE=10%' /etc/profile
cat >>/etc/profile<<EOF
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "
export PS1='[\[\e[31m\]\u@\[\e[36m\]\H \w]\\\$\[\e[m\] '
EOF

#20 audit setting
/bin/cp -i /etc/audit/audit.rules /etc/audit/audit.rules.bak
cat >>/etc/audit/audit.rules<<EOF
-w /var/log/audit/ -k LOG_audit
-w /etc/audit/ -p wa -k CFG_audit
-w /etc/sysconfig/auditd -p wa -k CFG_auditd.conf
-w /etc/libaudit.conf -p wa -k CFG_libaudit.conf
-w /etc/audisp/ -p wa -k CFG_audisp
-w /etc/cups/ -p wa -k CFG_cups
-w /etc/init.d/cups -p wa -k CFG_initd_cups
-w /etc/netlabel.rules -p wa -k CFG_netlabel.rules
-w /etc/selinux/mls/ -p wa -k CFG_MAC_policy
-w /usr/share/selinux/mls/ -p wa -k CFG_MAC_policy
-w /etc/selinux/semanage.conf -p wa -k CFG_MAC_policy
-w /usr/sbin/stunnel -p x
-w /etc/security/rbac-self-test.conf -p wa -k CFG_RBAC_self_test
-w /etc/aide.conf -p wa -k CFG_aide.conf
-w /etc/cron.allow -p wa -k CFG_cron.allow
-w /etc/cron.deny -p wa -k CFG_cron.deny
-w /etc/cron.d/ -p wa -k CFG_cron.d
-w /etc/cron.daily/ -p wa -k CFG_cron.daily
-w /etc/cron.hourly/ -p wa -k CFG_cron.hourly
-w /etc/cron.monthly/ -p wa -k CFG_cron.monthly
-w /etc/cron.weekly/ -p wa -k CFG_cron.weekly
-w /etc/crontab -p wa -k CFG_crontab
-w /var/spool/cron/root -k CFG_crontab_root
-w /etc/group -p wa -k CFG_group
-w /etc/passwd -p wa -k CFG_passwd
-w /etc/gshadow -k CFG_gshadow
-w /etc/shadow -k CFG_shadow
-w /etc/security/opasswd -k CFG_opasswd
-w /etc/login.defs -p wa -k CFG_login.defs
-w /etc/securetty -p wa -k CFG_securetty
-w /var/log/faillog -p wa -k LOG_faillog
-w /var/log/lastlog -p wa -k LOG_lastlog
-w /var/log/tallylog -p wa -k LOG_tallylog
-w /etc/hosts -p wa -k CFG_hosts
-w /etc/sysconfig/network-scripts/ -p wa -k CFG_network
-w /etc/inittab -p wa -k CFG_inittab
-w /etc/rc.d/init.d/ -p wa -k CFG_initscripts
-w /etc/ld.so.conf -p wa -k CFG_ld.so.conf
-w /etc/localtime -p wa -k CFG_localtime
-w /etc/sysctl.conf -p wa -k CFG_sysctl.conf
-w /etc/modprobe.conf -p wa -k CFG_modprobe.conf
-w /etc/pam.d/ -p wa -k CFG_pam
-w /etc/security/limits.conf -p wa -k CFG_pam
-w /etc/security/pam_env.conf -p wa -k CFG_pam
-w /etc/security/namespace.conf -p wa -k CFG_pam
-w /etc/security/namespace.init -p wa -k CFG_pam
-w /etc/aliases -p wa -k CFG_aliases
-w /etc/postfix/ -p wa -k CFG_postfix
-w /etc/ssh/sshd_config -k CFG_sshd_config
-w /etc/vsftpd.ftpusers -k CFG_vsftpd.ftpusers
-a exit,always -F arch=b32 -S sethostname
-w /etc/issue -p wa -k CFG_issue
-w /etc/issue.net -p wa -k CFG_issue.net
EOF
# restart audit service
service audit restart

#21 aide setting
#init aide
/usr/sbin/aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
echo "/usr/sbin/aide md5 checksum is:" >> /var/log/aide/aide_md5.txt
/usr/bin/md5sum /usr/sbin/aide >> /var/log/aide/aide_md5.txt
echo '45 23 * * * /usr/sbin/aide -C >> /var/log/aide/`date +\%Y-\%m-\%d`_aide.log' >> /var/spool/cron/root

#clean root directory
mkdir /root/backup
mv /root/* /root/backup/

# Start final steps
$SNIPPET('publickey_root_robin')
$SNIPPET('kickstart_done')
# End final steps
%end
