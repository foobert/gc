FROM ubuntu:trusty
MAINTAINER 0x002a@gmail.com

RUN apt-get update && apt-get install -y gpsbabel wget

VOLUME ["/data"]

ADD poi.sh /gpi/poi.sh
ENTRYPOINT ["/gpi/poi.sh"]
