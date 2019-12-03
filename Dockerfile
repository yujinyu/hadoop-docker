FROM ubuntu:18.04 as dev-env

# install development tools
RUN apt-get update && \
    apt-get install -y apt-utils wget tar build-essential \
    autoconf automake libtool cmake zlib1g-dev pkg-config \
	openjdk-8-jdk libssl-dev scala maven

# install protobuf 2.5.0
COPY Configs/protobuf-2.5.0.tar.gz /
RUN tar -xvf protobuf-2.5.0.tar.gz && cd protobuf-2.5.0/ \
	&& ./autogen.sh && ./configure && make && make install

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 HADOOP_HOME=/usr/local/hadoop
ENV PATH=${PATH}:${JAVA_HOME}/bin LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native:/usr/local/lib:${LD_LIBRARY_PATH}

# install and configure hadoop
COPY Configs/hadoop-3.1.2-src.tar.gz /
RUN tar -xvf hadoop-3.1.2-src.tar.gz && cd hadoop-3.1.2-src && \
    mvn package -Pdist,native -DskipTests -Dtar && \
    mv /hadoop-3.1.2-src/hadoop-dist/target/hadoop-3.1.2 ${HADOOP_HOME}
ADD Configs/core-site.xml.temple ${HADOOP_HOME}/etc/hadoop/core-site.xml.temple
ADD Configs/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
ADD Configs/mapred-site.xml ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
ADD Configs/yarn-site.xml ${HADOOP_HOME}/etc/hadoop/yarn-site.xml

FROM ubuntu:18.04
MAINTAINER yujinyu

COPY --from=dev-env /usr/local/hadoop /usr/local/hadoop
RUN useradd -ms /bin/bash hadoop && \
    useradd -ms /bin/bash yarn && \
    useradd -ms /bin/bash hdfs

RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean all

ENV HADOOP_HOME=/usr/local/hadoop JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=${PATH}:${JAVA_HOME}/bin:${HADOOP_HOME}/bin LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${HADOOP_HOME}/lib/native:/usr/local/lib HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop HADOOP_COMMON_HOME=${HADOOP_HOME} HADOOP_HDFS_HOME=${HADOOP_HOME} HADOOP_MAPRED_HOME=${HADOOP_HOME} HADOOP_YARN_HOME=${HADOOP_HOME}

# JAVA_HOME should be same to the version which has been installed above.
RUN echo "export JAVA_HOME=${JAVA_HOME}\nexport HADOOP_HOME=${HADOOP_HOME}\nexport HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> ${HADOOP_CONF_DIR}/hadoop-env.sh

ADD Configs/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh && \
    chmod +x ${HADOOP_CONF_DIR}/*-env.sh
#ENV BOOTSTRAP /etc/bootstrap.sh
CMD ["/etc/bootstrap.sh", "-d"]

# yarn port
EXPOSE 8030 8031 8032 8033 8040 8042 8044 8045 8046 8047 8048 8049 8088 8089 8090 8091 8188 8190 8788 9000 10200
# mapreduce port
EXPOSE 10020 10033 19888 19890