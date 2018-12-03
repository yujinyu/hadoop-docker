FROM yujinyu/ubuntu:ibmsdk8.0
MAINTAINER yujinyu

USER root

# install dev tools
RUN apt-get update && \
    apt-get install -y wget tar openssh-server openssh-client net-tools&& \
    apt-get autoremove -y && \
    apt-get clean all

# configure ssh --> passwordless ssh
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa && \
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD Configs/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config
# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "Port 2122" >> /etc/ssh/sshd_config

# get and configure hadoop
RUN wget http://mirrors.hust.edu.cn/apache/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz && \
    tar -xvf hadoop-2.8.5.tar.gz && rm hadoop-2.8.5.tar.gz && \
    mv hadoop-2.8.5 /usr/local/hadoop

ENV HADOOP_PREFIX=/usr/local/hadoop \
    HADOOP_HOME=/usr/local/hadoop \
    HADOOP_COMMON_HOME=/usr/local/hadoop \
    HADOOP_HDFS_HOME=/usr/local/hadoop \
    HADOOP_MAPRED_HOME=/usr/local/hadoop \
    HADOOP_YARN_HOME=/usr/local/hadoop \
    HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop \
    YARN_CONF_DIR=/usr/local/hadoop/etc/hadoop \
    JAVA_HOME=/usr/local/java/ \
    PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/local/java\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop/:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# pseudo distributed
ADD Configs/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
ADD Configs/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
ADD Configs/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
ADD Configs/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml

RUN $HADOOP_HOME/bin/hdfs namenode -format

ADD Configs/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && chmod 700 /etc/bootstrap.sh

# workingaround docker.io build error
RUN mkdir $HADOOP_HOME/input && cp $HADOOP_HOME/etc/hadoop/*.xml $HADOOP_HOME/input && \
    chmod +x $HADOOP_HOME/etc/hadoop/*-env.sh

RUN service ssh start && \
    $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    $HADOOP_HOME/sbin/start-dfs.sh && \
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/root && \
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /input && \
    $HADOOP_HOME/bin/hdfs dfs -put $HADOOP_HOME/input/* /input

RUN rm -rf $HADOOP_HOME/logs/*

CMD ["/etc/bootstrap.sh", "-d"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
