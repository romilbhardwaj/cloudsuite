FROM cloudsuite/cassandra:3.11.6

# ====================== Install JAVA8 ======================
# Install "software-properties-common" (for the "add-apt-repository")
RUN apt-get update && apt-get install -y \
    software-properties-common wget gnupg2

# Add the "JAVA" ppa
RUN wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
RUN add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
RUN apt-get update && apt-get install -y adoptopenjdk-8-hotspot

# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/adoptopenjdk-8-hotspot-amd64/
RUN export JAVA_HOME
# ====================== JAVA8 Install Done ======================

# ====================== SETUP YCSB ==============================
ENV YCSB_VERSION 0.14.0
ENV PYTHONUNBUFFERED 1

RUN set -ex \
    && apt-get update \
    && apt-get install -y wget nano \
    && wget -q --show-progress --progress=bar:force -O /tmp/cassandra-tools_${CASSANDRA_VERSION}_all.deb http://archive.apache.org/dist/cassandra/${CASSANDRA_VERSION}/debian/cassandra-tools_${CASSANDRA_VERSION}_all.deb \
    && dpkg --force-depends -i /tmp/cassandra-tools_${CASSANDRA_VERSION}_all.deb \
    && rm -rf /tmp/cassandra-tools_${CASSANDRA_VERSION}_all.deb


RUN wget -q --show-progress --progress=bar:force https://github.com/brianfrankcooper/YCSB/releases/download/$YCSB_VERSION/ycsb-$YCSB_VERSION.tar.gz -O /ycsb-$YCSB_VERSION.tar.gz \
    && tar -xzf /ycsb-$YCSB_VERSION.tar.gz && rm /ycsb-$YCSB_VERSION.tar.gz && mv /ycsb-$YCSB_VERSION /ycsb \
    && chown cassandra:cassandra -R /ycsb/workloads

# ====================== DONE SETUP YCSB ==============================

COPY files /scripts

RUN chmod +x /scripts/docker-entrypoint.sh

# For quicker bootstrapping
RUN echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.consistent.rangemovement=false\"" >> /etc/cassandra/cassandra-env.sh

RUN chmod +x /scripts/ready-probe.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]

CMD ["cassandra", "-R", "-f"]

EXPOSE 7000 7001 7199 9042 9160
