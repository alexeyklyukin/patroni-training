FROM ubuntu:18.04

ADD bootstrap.sh /

RUN bash -x bootstrap.sh

USER postgres

WORKDIR /var/lib/postgresql

ENTRYPOINT ["dumb-init"]

CMD ["etcd"]
