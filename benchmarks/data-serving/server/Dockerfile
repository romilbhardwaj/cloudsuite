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

COPY files /scripts

RUN chmod +x /scripts/docker-entrypoint.sh

# For quicker bootstrapping
RUN echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.consistent.rangemovement=false\"" >> /etc/cassandra/cassandra-env.sh

RUN chmod +x /scripts/ready-probe.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]

CMD ["cassandra", "-R", "-f"]

EXPOSE 7000 7001 7199 9042 9160
