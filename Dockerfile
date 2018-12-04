FROM yujinyu/ubuntu:ibmsdk8.0
MAINTAINER yujinyu

USER root

# install dev tools
RUN apt-get update && \
    apt-get install -y curl wget tar git openssh-server openssh-client openjdk-8-jdk && \
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
    echo "UsePAM no" >> /etc/ssh/sshd_config


ENV JAVA_HOME /usr/local/java
ENV PATH $PATH:$JAVA_HOME/bin

# install and configure hadoop
RUN wget http://192.168.6.155/hadoop/common/hadoop-3.1.1/hadoop-3.1.1.tar.gz
RUN tar -xvf hadoop-3.1.1.tar.gz && mv hadoop-3.1.1 /usr/local/hadoop && rm -rf hadoop-3.1.1.tar.gz

ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# pseudo distributed
ADD Configs/core-site.xml.temple $HADOOP_HOME/etc/hadoop/core-site.xml.temple
ADD Configs/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
ADD Configs/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
ADD Configs/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml

ADD Configs/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && chmod 700 /etc/bootstrap.sh
ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh

CMD ["/etc/bootstrap.sh", "-d"]

# yarn port
EXPOSE 8030 8031 8032 8033 8040 8042 8088 9000
# hdfs port
EXPOSE 9864 9866 9867 9868 9870
# mapreduce port
EXPOSE 10020 10033 19888
# other port
EXPOSE 49707 22
