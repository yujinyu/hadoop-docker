# Creates pseudo distributed hadoop 2.7.7

FROM tianon/centos:6.5
MAINTAINER yujinyu

USER root

# install dev tools
RUN yum clean all; \
    rpm --rebuilddb; \
	yum install -y curl tar wget openssh-server openssh-client; \
	yum update -y libselinux

# passwordless ssh
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
	ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
	ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
	cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
ADD Configs/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && chown root:root /root/.ssh/config
# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config && \
	echo "UsePAM no" >> /etc/ssh/sshd_config && \
	echo "Port 2122" >> /etc/ssh/sshd_config
	
# install and configure java
RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie"  https://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-linux-x64.rpm
RUN rpm -i jdk-8u191-linux-x64.rpm
RUN rm jdk-8u191-linux-x64.rpm
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

# hadoop
RUN cd /usr/local/ && wget http://mirrors.hust.edu.cn/apache/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz && \
	tar -xvf hadoop-2.7.7.tar.gz && rm hadoop-2.7.7.tar.gz && mv hadoop-2.7.7 hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_HDFS_HOME=/usr/local/hadoop
ENV HADOOP_MAPRED_HOME=/usr/local/hadoop
ENV HADOOP_YARN_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR=/usr/local/hadoop/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input && cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD Configs/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD Configs/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD Configs/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD Configs/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

ADD Configs/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
	chmod 700 /etc/bootstrap.sh
ENV BOOTSTRAP /etc/bootstrap.sh

RUN chmod +x $HADOOP_PREFIX/etc/hadoop/*-env.sh
RUN $HADOOP_PREFIX/bin/hdfs namenode -format
RUN service sshd start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
RUN service sshd start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

CMD ["/etc/bootstrap.sh", "-d"]

EXPOSE 50020 50090 50070 50010 50075 8031 8032 8033 8040 8042 49707 2122 8088 8030
#EXPOSE 8020 10020 19888 8030
