#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
ARG image_tag=24.04

FROM ubuntu:${image_tag}
LABEL org.opencontainers.image.authors="Apache Spark project <dev@spark.apache.org>"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.ref.name="Apache Spark Scala/Java Image"
# Overwrite this label to avoid exposing the underlying Ubuntu OS version label
LABEL org.opencontainers.image.version=""

ARG spark_uid=185

# Before building the docker image, first build and make a Spark distribution following
# the instructions in https://spark.apache.org/docs/latest/building-spark.html.
# If this docker file is being used in the context of building your images from a Spark
# distribution, the docker build command should be invoked from the top level directory
# of the Spark distribution. E.g.:
# docker build -t spark:latest -f kubernetes/dockerfiles/spark/Dockerfile .

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps net-tools logrotate libssl-dev git curl openjdk-21-jdk python3 python3-pip ca-certificates gnupg unzip && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

RUN mkdir ${SPARK_HOME}/python
RUN ln -s /opt/spark/libs /opt/spark/jars

# Copy hive-jackson directory if exists
COPY hive-jackso[n] /opt/spark/hive-jackson
# Copy RELEASE file if exists
COPY RELEAS[E] /opt/spark/RELEASE
COPY bin /opt/spark/bin
COPY sbin /opt/spark/sbin
COPY resource-managers/kubernetes/docker/src/main/dockerfiles/spark/entrypoint.sh /opt/
COPY resource-managers/kubernetes/docker/src/main/dockerfiles/spark/decom.sh /opt/
COPY examples /opt/spark/examples
COPY data /opt/spark/data

ENV SPARK_HOME=/opt/spark

COPY python/pyspark ${SPARK_HOME}/python/pyspark
COPY python/lib ${SPARK_HOME}/python/lib

WORKDIR /opt/spark/work-dir
RUN chown -R ${spark_uid}:root /opt/spark
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}
