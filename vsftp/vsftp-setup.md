## vsftpd 生产配置

##### 今天为同事在测试环境搭建了一套vsftp环境,简要记录下

##### 1. 环境说明

  - 系统: CentOS6.6 x86_64
  - 安装方法: yum
  - 数据目录: /var/ftp/vroot/
  - vsftpd用户: virtusers
  - ftp 用户认证过程 ftp --> user/pwd --> pam ---> /etc/pam.d/vsftpd/ ---> /etc/vsftpd/virtusers.db
  
  
##### 2. 安装

    # yum install vsftpd
    # yum install ftp
    # yum install db4-* db4-devel-*
    # useradd virtusers -s /sbin/nologin
    # setenforce 0
    
##### 3. 配置

3.1 配置vsftpd.conf

    # Example config file /etc/vsftpd/vsftpd.conf
    #
    # The default compiled in settings are fairly paranoid. This sample file
    # loosens things up a bit, to make the ftp daemon more usable.
    # Please see vsftpd.conf.5 for all compiled in defaults.
    #
    # READ THIS: This example file is NOT an exhaustive list of vsftpd options.
    # Please read the vsftpd.conf.5 manual page to get a full idea of vsftpd's
    # capabilities.
    #
    # Allow anonymous FTP? (Beware - allowed by default if you comment this out).
    anonymous_enable=NO
    #
    # Uncomment this to allow local users to log in.
    local_enable=YES
    #
    # Uncomment this to enable any form of FTP write command.
    write_enable=YES
    #
    # Default umask for local users is 077. You may wish to change this to 022,
    # if your users expect that (022 is used by most other ftpd's)
    local_umask=022
    #
    # Uncomment this to allow the anonymous FTP user to upload files. This only
    # has an effect if the above global write enable is activated. Also, you will
    # obviously need to create a directory writable by the FTP user.
    anon_upload_enable=NO
    #
    # Uncomment this if you want the anonymous FTP user to be able to create
    # new directories.
    anon_mkdir_write_enable=NO
    #
    # Activate directory messages - messages given to remote users when they
    # go into a certain directory.
    dirmessage_enable=YES
    #
    # The target log file can be vsftpd_log_file or xferlog_file.
    # This depends on setting xferlog_std_format parameter
    xferlog_enable=YES
    #
    # Make sure PORT transfer connections originate from port 20 (ftp-data).
    connect_from_port_20=YES
    #
    # If you want, you can arrange for uploaded anonymous files to be owned by
    # a different user. Note! Using "root" for uploaded files is not
    # recommended!
    chown_uploads=NO
    #chown_username=whoever
    #chroot_local_user=YES
    #
    # The name of log file when xferlog_enable=YES and xferlog_std_format=YES
    # WARNING - changing this filename affects /etc/logrotate.d/vsftpd.log
    xferlog_file=/var/log/xferlog
    #
    # Switches between logging into vsftpd_log_file and xferlog_file files.
    # NO writes to vsftpd_log_file, YES to xferlog_file
    xferlog_std_format=YES
    #
    # You may change the default value for timing out an idle session.
    #idle_session_timeout=600
    #
    # You may change the default value for timing out a data connection.
    #data_connection_timeout=120
    #
    # It is recommended that you define on your system a unique user which the
    # ftp server can use as a totally isolated and unprivileged user.
    #nopriv_user=ftpsecure
    nopriv_user=vsftpd
    #
    # Enable this and the server will recognise asynchronous ABOR requests. Not
    # recommended for security (the code is non-trivial). Not enabling it,
    # however, may confuse older FTP clients.
    async_abor_enable=YES
    #
    # By default the server will pretend to allow ASCII mode but in fact ignore
    # the request. Turn on the below options to have the server actually do ASCII
    # mangling on files when in ASCII mode.
    # Beware that on some FTP servers, ASCII support allows a denial of service
    # attack (DoS) via the command "SIZE /big/file" in ASCII mode. vsftpd
    # predicted this attack and has always been safe, reporting the size of the
    # raw file.
    # ASCII mangling is a horrible feature of the protocol.
    ascii_upload_enable=YES
    ascii_download_enable=YES
    #
    # You may fully customise the login banner string:
    ftpd_banner=Welcome to blah FTP service.
    #
    # You may specify a file of disallowed anonymous e-mail addresses. Apparently
    # useful for combatting certain DoS attacks.
    #deny_email_enable=YES
    # (default follows)
    #banned_email_file=/etc/vsftpd/banned_emails
    #
    # You may specify an explicit list of local users to chroot() to their home
    # directory. If chroot_local_user is YES, then this list becomes a list of
    # users to NOT chroot().
    #chroot_local_user=YES
    chroot_list_enable=NO
    # (default follows)
    #chroot_list_file=/etc/vsftpd/chroot_list
    #
    # You may activate the "-R" option to the builtin ls. This is disabled by
    # default to avoid remote users being able to cause excessive I/O on large
    # sites. However, some broken FTP clients such as "ncftp" and "mirror" assume
    # the presence of the "-R" option, so there is a strong case for enabling it.
    ls_recurse_enable=NO
    #
    # When "listen" directive is enabled, vsftpd runs in standalone mode and
    # listens on IPv4 sockets. This directive cannot be used in conjunction
    # with the listen_ipv6 directive.
    listen=YES
    #
    # This directive enables listening on IPv6 sockets. To listen on IPv4 and IPv6
    # sockets, you must run two copies of vsftpd with two configuration files.
    # Make sure, that one of the listen options is commented !!
    #listen_ipv6=YES
    
    # This is the file : /etc/pam.d/vsftpd
    pam_service_name=vsftpd
    userlist_enable=YES
    tcp_wrappers=YES
    
    guest_enable=YES
    
    # 虚拟用户映射到 virtusers 这个系统用户
    guest_username=virtusers
    virtual_use_local_privs=YES
    
    # 虚拟用户的配置文件位置
    user_config_dir=/etc/vsftpd/vconf
    
    pasv_enable=yes
    pasv_min_port=3000
    pasv_max_port=3010
    
    anon_world_readable_only=NO
    anon_upload_enable=YES
    anon_mkdir_write_enable=YES
    anon_other_write_enable=YES
    
3.2 配置 /etc/pam.d/vsftpd
    
    # cat /etc/pam.d/vsftpd
    
     cat /etc/pam.d/vsftpd
    # %PAM-1.0
    auth    required      /lib64/security/pam_userdb.so     db=/etc/vsftpd/virtusers
    account required      /lib64/security/pam_userdb.so     db=/etc/vsftpd/virtusers
    
3.3 配置相关的目录

    # mkdir -p /var/ftp/vroot/
    # chown -R virtusers.virtusers /var/ftp/vroot/
    
    # mkdir /etc/vsftpd/vconf
    
3.4 配置虚拟用户

    # cat /etc/vsftpd/virtusers
    
        500
        123456
        501
        123456
        520
        123456
    
    # db_load -T -t hash -f virtusers /etc/vsftpd/virtusers.db
    # mkdir -p /var/ftp/vroot/{500,501,520}
    # chown -R /var/ftp/vroot/
    
    # cat /etc/vsftpd/vconf/500
    
        local_root=/var/ftp/vroot/500
        #这个就是以后要指定虚拟的具体主路径。
        anonymous_enable=NO
        #设定不允许匿名用户访问。
        write_enable=YES
        #设定允许写操作
        local_umask=022
        #设定上传文件权限掩码
        anon_upload_enable=YES
        #设定不允许匿名用户上传。
        anon_mkdir_write_enable=YES
        #设定不允许匿名用户建立目录。
        idle_session_timeout=300
        #设定空闲连接超时时间。
        data_connection_timeout=90
        #设定单次连续传输最大时间。
        max_clients=1
        #设定并发客户端访问个数。
        max_per_ip=1
        #设定单个客户端的最大线程数，这个配置主要来照顾Flashget、迅雷等多线程下载软件。
        #local_max_rate=25000
        #设定该用户的最大传输速率，单位b/s。
        pam_service_name=vsftpd
        chroot_local_user=NO
        virtual_use_local_privs=NO
        anon_world_readable_only=NO
        
3.5 启动vsftpd 并测试

    # service vsftpd restart
    
    # ftp localhost
    
    ftp> ls 
    ftp> put xxx


        