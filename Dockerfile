FROM ubuntu:16.04

ADD bootstrap.sh /

RUN bash -x bootstrap.sh

CMD ["/bin/etcd"]
