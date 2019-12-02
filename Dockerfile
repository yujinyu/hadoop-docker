FROM ubuntu:18.04 as dev-env
WORKDIR /
# install development tools
RUN apt-get update && \
    apt-get install -y apt-utils wget tar build-essential \
    autoconf automake libtool cmake zlib1g-dev pkg-config \
	openjdk-8-jdk libssl-dev scala maven

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$PATH:${JAVA_HOME}/bin

# install protobuf 2.5.0
#RUN wget https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.gz
COPY Configs/protobuf-2.5.0.tar.gz /
RUN tar -xvf protobuf-2.5.0.tar.gz && cd protobuf-2.5.0/ \
	&& ./autogen.sh && ./configure && make && make install
ENV LD_LIBRARY_PATH=/usr/local/lib

# install and configure hadoop
COPY Configs/hadoop-3.1.2-src.tar.gz /
RUN tar -xvf hadoop-3.1.2-src.tar.gz && cd hadoop-3.1.2-src && mvn package -Pdist,native -DskipTests -Dtar

FROM ubuntu:18.04
MAINTAINER yujinyu
USER root
COPY --from=dev-env /hadoop-3.1.2-src/hadoop-dist/target/hadoop-3.1.2 /opt/hadoop
# add hadoop user
RUN useradd -ms /bin/bash hadoop && \
    useradd -ms /bin/bash yarn && \
    useradd -ms /bin/bash hdfs

RUN apt-get update && \
    apt-get install -y openssh-server openssh-client openjdk-8-jdk && \
    apt-get autoremove -y && \
    apt-get clean all
# configure ssh --> passwordless ssh
ADD Configs/ssh_config /root/.ssh/config
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa && \
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config && \
    sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config

ENV HADOOP_HOME=/usr/local/hadoop
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${HADOOP_HOME}/lib/native:/usr/local/lib HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
ENV HADOOP_PREFIX=/usr/local/hadoop HADOOP_COMMON_HOME=/usr/local/hadoop HADOOP_HDFS_HOME=/usr/local/hadoop HADOOP_MAPRED_HOME=/usr/local/hadoop HADOOP_YARN_HOME=/usr/local/hadoop
ENV PATH=$PATH:${JAVA_HOME}/bin:$HADOOP_HOME/bin

# pseudo distributed
ADD Configs/core-site.xml.temple ${HADOOP_HOME}/etc/hadoop/core-site.xml.temple
ADD Configs/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
ADD Configs/mapred-site.xml ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
ADD Configs/yarn-site.xml ${HADOOP_HOME}/etc/hadoop/yarn-site.xml
# JAVA_HOME should be same to the version which has been installed above.
RUN echo "export JAVA_HOME=${JAVA_HOME}\nexport HADOOP_HOME=${HADOOP_HOME}\nexport HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" \
 >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

ADD Configs/bootstrap.sh /etc/bootstrap.sh
ENV BOOTSTRAP /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh && \
    chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh

CMD ["/etc/bootstrap.sh", "-d"]

# yarn port
EXPOSE 8030 8031 8032 8033 8040 8042 8044 8045 8046 8047 8048 8049 8088 8089 8090 8091 8188 8190 8788 9000 10200
# hdfs port
EXPOSE 8480 8481 8485 9864 9865 9866 9867 9868 9869 9870 9871 50200
# mapreduce port
EXPOSE 10020 10033 19888 19890
# ssh port
EXPOSE 22