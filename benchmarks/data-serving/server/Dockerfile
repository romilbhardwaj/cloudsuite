FROM cloudsuite/cassandra:3.11.6

COPY files /scripts

RUN chmod +x /scripts/docker-entrypoint.sh

# For quicker bootstrapping
RUN echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.consistent.rangemovement=false\"" >> /etc/cassandra/cassandra-env.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]

CMD ["cassandra", "-R", "-f"]

EXPOSE 7000 7001 7199 9042 9160
