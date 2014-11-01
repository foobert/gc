FROM ubuntu:trusty
MAINTAINER 0x002a@gmail.com

# Update package sources.
RUN apt-get update

# Install rethinkdb. Adopted from http://rethinkdb.com/docs/install/ubuntu/
RUN echo "deb http://download.rethinkdb.com/apt trusty main" > /etc/apt/sources.list.d/rethinkdb.list && \
    apt-get install -y wget && \
    wget -qO- http://download.rethinkdb.com/apt/pubkey.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y rethinkdb

# Create db direcory.
RUN mkdir /db

EXPOSE 8080 28015 29015

VOLUME ["/db"]
WORKDIR /db
ENTRYPOINT ["/usr/bin/rethinkdb"]
CMD ["--bind", "all"]
