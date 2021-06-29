FROM cloudsuite/data-serving:server

COPY files/ready-probe.sh /ready-probe.sh
RUN chmod +x /ready-probe.sh

CMD ["cassandra"]
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 7000 7001 7199 9042 9160