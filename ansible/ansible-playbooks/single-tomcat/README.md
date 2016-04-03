## 四. 从实例学习playbook

###  场景一 : 安装一个tomcat
----------------------------
#### 1. 环境说明

    环境说明:
    os=ubuntu14.04 LTS
    tomcat 7 + jdk 1.7 
    端口号:8080
    shudown端口:9080
    servers:仍然是两台docker容器和一台虚拟机
    192.168.99.100:10022
    192.168.99.100:10023
    192.168.99.104

##### 仍然希望使用docker完成测试(省时省事啊)

    docker 基础镜像名字为: sshd:dockerfile
    这是我自己的镜像仓库中得镜像
    这个镜像只是再unbutu系统镜像的基础上, 开放了ssh服务, 这样比较方便进行测试和研究
  
##### 先整理下思路(手工的安装过程)
  
    a. 安装JDK
    sudo apt-get install xxxxxx
    b. 下载, 部署tomcat
        b.1 添加普通用户\用户组
        b.2 建立tomcat所在目录 比如~/server/
        b.3 下载tomcat
        b.4 解压tomcat包
        b.5 重命名tomcat目录, 比如 app01-8080-tomcat-xxxxx
        b.6 配置tomcat server.xml
        b.7 配置tomcat环境变量(java等)
        b.8 修改tomcat启动控制脚本
    
##### 2. playbook基础环境

##### 先建好playbooks存放的目录 on myMac
    
    $ mkdir -p ~/PycharmProjects/MyConfigurations/ansible/ansible-playbooks/single-tomcat
    
##### 然后在single-tomcat下建立第一个playbook的目录结构
    
    $ cd ~/PycharmProjects/MyConfigurations/ansible/ansible-playbooks/single-tomcat
    $ mkdir -p roles/jdk/tasks
    $ touch site.yml hosts README.md ./roles/jdk/tasks/main.yml
    
##### 看一下目录和文件结构
    
    $ cd ~/PycharmProjects/MyConfigurations/ansible/ansible-playbooks
    $ tree ./single-tomcat
    
    .
    |____single-tomcat
    | |____hosts
    | |____README.md
    | |____roles
    | | |____jdk
    | | | |____tasks
    | | | | |____main.yml
    | |____site.yml


##### 3. 配置playbook
3.1 参考 /etc/ansible/hosts 配置hosts, 定义主机组
    
    $ cat hosts
    [tomcat-servers]
    aserver         ansible_port=10022      ansible_host=192.168.99.100     ansible_user=root
    bserver         ansible_port=10023      ansible_host=192.168.99.100     ansible_user=root

3.2 配置 site.yml

    $ cat site.yml
    
    ---
    # This playbook deploy an openjdk to docker container

    - hosts: all
      user:root
      vars:
        - jdk_version: openjdk-7-jdk
      roles:
        - jdk

3.3 配置main.yml

    $ cat main.yml

    - name: Install  jdk  (Debian based)
      apt: name={{ jdk_version }} state=present
      when:  ansible_pkg_mgr == "apt"
      
3.4 这就配置好了一个简单但是并不完整的playbook结构, 看起来并不困难
      
3.5 下面该是测试运行的时候了, 先检查配置, 再运行

    $ ansible-playbook ./site.yml --syntax-check
    
    playbook: ./site.yml
    
    $ ansible-playbook ./site.yml -f 2
    

    PLAY [all] *********************************************************************

    TASK [setup] *******************************************************************
    ok: [bserver]
    ok: [aserver]
    ok: [my-ubuntu]
    
    TASK [jdk : Install  jdk  (Debian based)] **************************************
    changed: [aserver]
    fatal: [my-ubuntu]: FAILED! => {"cache_update_time": 0, "cache_updated": false, "changed": false, "failed": true, "msg": "'/usr/bin/apt-get -y -o \"Dpkg::Options::=--force-confdef\" -o \"Dpkg::Options::=--force-confold\"     install 'openjdk-7-jdk'' failed: E: Could not open lock file /var/lib/dpkg/lock - open (13: Permission denied)\nE: Unable to lock the administration directory (/var/lib/dpkg/), are you root?\n", "stderr": "E: Could not open lock file /var/lib/dpkg/lock - open (13: Permission denied)\nE: Unable to lock the administration directory (/var/lib/dpkg/), are you root?\n", "stdout": "", "stdout_lines": []}
    changed: [bserver]
    
    NO MORE HOSTS LEFT *************************************************************
    
    PLAY RECAP *********************************************************************
    aserver                    : ok=2    changed=1    unreachable=0    failed=0   
    bserver                    : ok=2    changed=1    unreachable=0    failed=0   
    my-ubuntu                  : ok=1    changed=0    unreachable=0    failed=1   

3.6 发现一个问题, 我们在本地目录定义的hosts没有起作用, 还是使用的 ansible 的全局 hosts 配置文件
  因为my-ubuntu这台机器的用户没有root权限, 也没有配置sudu, 因此安装jdk失败了
  这个问题是因为我们没有指定hosts文件, 下面加个 -i 参数来测试看看
  
    $ ansible-playbook ./site.yml -i ./hosts --list-host
    
    playbook: ./site.yml

    play #1 (all): all	TAGS: []
    pattern: [u'all']
    hosts (2):
      bserver
      aserver
      
  这样就对了, 只有aserver 和 bserver, 不再受/etc/ansible/hosts 的影响
  
3.7 弄明白这个问题, 那我们看看之前安装成功的两个容器内的java jdk是否 ok
  进入 容器的 shell
  
    $ ssh -p 10022 root@192.168.99.100
    
    root@a03aa95eb9d2:~# java -version
    
    java version "1.7.0_95"
    OpenJDK Runtime Environment (IcedTea 2.6.4) (7u95-2.6.4-0ubuntu0.14.04.2)
    OpenJDK 64-Bit Server VM (build 24.95-b01, mixed mode)
    
  成功, 容器内已经安装了我们指定版本的JDK
  
3.8 场景一配置总结

  - ansible的playbook, 配置起来并不复杂, 相当容易, 很好上手
  - yaml格式文件编写的时候, 还是要特别注意格式
  - ansible安装的时候 默认把 hosts文件放在了 /etc/ansible/下, 如果指定使用我们自定义的hosts 需要使用 -i 参数指定文件位置
  - 可以发现, 统一的配管系统, 还是最好使用统一的用户权限, 避免因权限差距导致的失败
  - ansible playbook 在运行过程中的各种信息还是比较全面的, 我们可以通过仔细定义 -name 来完善这些信息
  - ansible playbook 在执行完成后由比较详细的执行结果, 我们可以将执行结果输出到文件, 方便后续阅读或通过程序处理形成报告
  - 针对一两台机器编写 playbook 似乎并没有什么优势, 但是面对几十\几百\几千\甚至更多的时候, 就非常的有用了
  - 通过把常用软件的安装 配置 更新等, 编写为play book, 能使未来的工作变得非常轻松
  

  
