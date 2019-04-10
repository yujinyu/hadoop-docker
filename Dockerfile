FROM ubuntu:16.04
MAINTAINER yujinyu

USER root

# install dev tools
RUN apt-get update && \
    apt-get install -y apt-utils wget tar openssh-server openssh-client && \
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

# install and config java
RUN wget http://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/8.0.5.31/linux/x86_64/ibm-java-x86_64-sdk-8.0-5.31.bin && \
    chmod +x ibm-java-x86_64-sdk-8.0-5.31.bin
RUN sh -c '/bin/echo -e "\n4\n1\n\n/usr/java/default\nY\n\n\n" | ./ibm-java-x86_64-sdk-8.0-5.31.bin'
ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm -f ibm-java-x86_64-sdk-8.0-5.31.bin 

# install and configure hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.1.2/hadoop-3.1.2.tar.gz
RUN tar -xvf hadoop-3.1.2.tar.gz && mv hadoop-3.1.2 /usr/local/hadoop && rm -rf hadoop-3.1.2.tar.gz

ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/local/java\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# pseudo distributed
ADD Configs/core-site.xml.temple $HADOOP_PREFIX/etc/hadoop/core-site.xml.temple
ADD Configs/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD Configs/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD Configs/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

ADD Configs/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && chmod 700 /etc/bootstrap.sh
ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh

CMD ["/etc/bootstrap.sh", "-d"]

# yarn port
EXPOSE 8030 8031 8032 8033 8040 8042 8044 8045 8046 8047 8048 8049 8088 8089 8090 8091 8188 8190 8788 9000 10200
# hdfs port
EXPOSE 8480 8481 8485 9864 9865 9866 9867 9868 9869 9870 9871 50200
# mapreduce port
EXPOSE 10020 10033 19888 19890
# ssh port
EXPOSE 22
# other port
EXPOSE 49707
