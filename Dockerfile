FROM ubuntu:18.04

RUN useradd -ms /bin/bash hadoop && \
    useradd -ms /bin/bash yarn && \
    useradd -ms /bin/bash hdfs && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/apt/periodic/* && \
    rm -rf /var/log/*log*
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=${PATH}:${JAVA_HOME}/bin

