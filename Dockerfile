FROM ubuntu:18.04 as dev-env

# install development tools
#ADD Configs/sources.list /etc/apt/sources.list
#ADD Configs/settings.xml /root/.m2/settings.xml
RUN apt-get update
RUN apt-get install -y apt-utils wget tar build-essential \
    autoconf automake libtool cmake zlib1g-dev pkg-config \
	openjdk-8-jdk libssl-dev scala maven

# install protobuf 2.5.0
ADD Configs/protobuf-2.5.0.tar.gz /
RUN cd protobuf-2.5.0/ && ./autogen.sh && ./configure
RUN cd protobuf-2.5.0/ && make && make install

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=${PATH}:${JAVA_HOME}/bin
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native:/usr/local/lib:${LD_LIBRARY_PATH}
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

# install and configure hadoop
ADD Configs/hadoop-3.1.2-src.tar.gz /
RUN cd hadoop-3.1.2-src && mvn package -Pdist,native -DskipTests -Dtar
RUN mv hadoop-3.1.2-src/hadoop-dist/target/hadoop-3.1.2 ${HADOOP_HOME}
ADD Configs/core-site.xml.temple ${HADOOP_CONF_DIR}/core-site.xml.temple
ADD Configs/hdfs-site.xml ${HADOOP_CONF_DIR}/hdfs-site.xml
ADD Configs/mapred-site.xml ${HADOOP_CONF_DIR}/mapred-site.xml
ADD Configs/yarn-site.xml ${HADOOP_CONF_DIR}/yarn-site.xml

FROM ubuntu:18.04

COPY --from=dev-env /usr/local/hadoop /usr/local/hadoop
#ADD Configs/sources.list /etc/apt/sources.list
RUN useradd -ms /bin/bash hadoop && \
    useradd -ms /bin/bash yarn && \
    useradd -ms /bin/bash hdfs && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean all

ENV HADOOP_HOME=/usr/local/hadoop JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop HADOOP_COMMON_HOME=${HADOOP_HOME} \
    HADOOP_HDFS_HOME=${HADOOP_HOME} HADOOP_MAPRED_HOME=${HADOOP_HOME} HADOOP_YARN_HOME=${HADOOP_HOME} \
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${HADOOP_HOME}/lib/native:/usr/local/lib \
    PATH=${PATH}:${JAVA_HOME}/bin:${HADOOP_HOME}/bin

# JAVA_HOME should be same to the version which has been installed above.
RUN echo "export JAVA_HOME=${JAVA_HOME}\nexport HADOOP_HOME=${HADOOP_HOME}\nexport HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> \
    ${HADOOP_CONF_DIR}/hadoop-env.sh

ADD Configs/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh && \
    chmod +x ${HADOOP_CONF_DIR}/*-env.sh

CMD ["/etc/bootstrap.sh", "-d"]