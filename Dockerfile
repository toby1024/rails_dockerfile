FROM daocloud.io/library/ruby:2.3.1

ENV RAILS_VERSION 5.0.0.1
ENV APP_HOME /rails_app
# 项目代码放在rails_app目录下
RUN mkdir -p $APP_HOME && \
    #将官方gem源替换成ruby-china源
    # gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/ && \
    #安装指定rails版本
    gem install rails --version "$RAILS_VERSION" && \
    #修改时区
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # Install our PGP key and add HTTPS support for APT
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates && \
    # 加上passenger的APT repository
    sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger jessie main > /etc/apt/sources.list.d/passenger.list' && \
    #install passenger
    apt-get install -y passenger && \
    #install nodejs
    apt-get install -y nodejs --no-install-recommends && \
    #install mysql-client or postgresql-client sqlite3
    apt-get install -y mysql-client --no-install-recommends 
    #安装中文字符集zh_CN.UTF-8支持
RUN apt-get -y install locales && \
    sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="zh_CN.UTF-8"' > /etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=zh_CN.UTF-8 && \
    #安装net-tools Telnet
    #apt-get -y install telnet net-tools && \
    #安装logrotate rsyslog 日志服务
    apt-get -y install logrotate rsyslog 
    #安装sendemail服务
    #apt-get -y install sendemail && \
    # 安装sshd服务
RUN apt-get -y install openssh-server pwgen vim cron && \
    mkdir -p /var/run/sshd && \
    mkdir -p /var/log/supervisor && \
    sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && \
    sed -i "s@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g" /etc/pam.d/sshd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    #编辑/etc/crontab,修改cron.daily启动logrotate的时间
    sed -i 's/^[0-9]\+.*[0-9]\+\(.*\/etc\/cron\.daily.*$\)/59 23\1/g' /etc/crontab && \
    #修改logrotate配置,增加-f参数,强制执行日志切分 
    sed  -i '/^\/usr\/sbin\/logrotate/d' /etc/cron.daily/logrotate && \
    echo "/usr/sbin/logrotate -f /etc/logrotate.conf" >> /etc/cron.daily/logrotate && \
    #把cron日志打开
    sed -i 's/#cron\.\*/cron.*/g' /etc/rsyslog.conf
    #开启ll快捷命令代替ls -l
RUN echo "alias ll='ls \$LS_OPTIONS -l'" >> ~/.bashrc && \
    # set ssh user source,为通过ssh进来的shell导出必要的环境变量
    echo "export APP_HOME=${APP_HOME}" >> ${HOME}/.bashrc && \
    echo "export GEM_HOME=${GEM_HOME}" >> ${HOME}/.bashrc && \
    echo "export BUNDLE_PATH=${BUNDLE_PATH}" >> ${HOME}/.bashrc && \
    echo "export BUNDLE_BIN=${BUNDLE_BIN}" >> ${HOME}/.bashrc && \
    echo "export BUNDLE_SILENCE_ROOT_WARNING=1" >> ${HOME}/.bashrc && \
    echo "export BUNDLE_APP_CONFIG=${BUNDLE_APP_CONFIG}" >> ${HOME}/.bashrc && \
    echo "export PATH=${PATH}" >> ${HOME}/.bashrc && \
    echo "export TERM=xterm" >> ~/.bashrc && \
    echo "export LANG=zh_CN.UTF-8" >> ${HOME}/.bashrc && \
    echo "export LANGUAGE=zh_CN.UTF-8" >> ${HOME}/.bashrc && \
    echo "export LC_ALL=zh_CN.UTF-8" >> ${HOME}/.bashrc
# set work dir
WORKDIR $APP_HOME
