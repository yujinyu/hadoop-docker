FROM ubuntu:18.04 as build

RUN apt-get update && apt-get install -y wget tar
# install and configure hadoop
ENV HADOOP_HOME=/opt/hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.1.2/hadoop-3.1.2.tar.gz
RUN tar -xvf hadoop-3.1.2.tar.gz && rm -rf hadoop-3.1.2/share/doc && mv hadoop-3.1.2 ${HADOOP_HOME}

ADD Configs/core-site.xml.temple ${HADOOP_HOME}/etc/hadoop/core-site.xml.temple
ADD Configs/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
ADD Configs/mapred-site.xml ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
ADD Configs/yarn-site.xml ${HADOOP_HOME}/etc/hadoop/yarn-site.xml

FROM ubuntu:18.04
MAINTAINER yujinyu
USER root

COPY --from=build /opt/ /opt/

# add users
RUN useradd -ms /bin/bash hadoop && \
	useradd -ms /bin/bash yarn && \
	useradd -ms /bin/bash hdfs

# install dev tools
RUN apt-get update && \
    apt-get install -y openssh-server openssh-client openjdk-8-jdk && \
    apt-get autoremove -y && apt-get clean all && \
    rm /var/log/*.log && rm /var/log/apt/*.log

# configure passwordless ssh
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa && \
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD Configs/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config

# configure System Envs
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 HADOOP_HOME=/opt/hadoop
ENV HADOOP_PREFIX=${HADOOP_HOME} HADOOP_COMMON_HOME=${HADOOP_HOME} HADOOP_HDFS_HOME=${HADOOP_HOME} HADOOP_MAPRED_HOME=${HADOOP_HOME} HADOOP_YARN_HOME=${HADOOP_HOME} HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop PATH=$PATH:${JAVA_HOME}/bin:${HADOOP_HOME}/bin

# JAVA_HOME should be same to the version which has been installed above.
RUN echo "export JAVA_HOME=${JAVA_HOME}\nexport HADOOP_HOME=${HADOOP_HOME}\nHADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> ${HADOOP_PREFIX}/etc/hadoop/hadoop-env.sh

ADD Configs/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && chmod 700 /etc/bootstrap.sh
ENV BOOTSTRAP=/etc/bootstrap.sh
CMD ["/etc/bootstrap.sh", "-d"]

# yarn port
EXPOSE 8030 8031 8032 8033 8040 8042 8044 8045 8046 8047 8048 8049 8088 8089 8090 8091 8188 8190 8788 9000 10200
# hdfs port
EXPOSE 8480 8481 8485 9864 9865 9866 9867 9868 9869 9870 9871 50200
# mapreduce port
EXPOSE 10020 10033 19888 19890
# ssh port
EXPOSE 22
