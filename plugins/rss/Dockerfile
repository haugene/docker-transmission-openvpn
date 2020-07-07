FROM ubuntu:16.04
MAINTAINER Kristian Haugene

# Update packages and install software
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install curl gcc make ruby2.3-dev \
    && gem install transmission-rss \
    && curl -L https://github.com/jwilder/dockerize/releases/download/v0.5.0/dockerize-linux-amd64-v0.5.0.tar.gz | tar -C /usr/local/bin -xzv

ADD . /etc/transmission-rss

ENV TRANSMISSION_DOWNLOAD_DIR=/data/completed \
    RSS_URL=**None** \
    RSS_REGEXP=

CMD ["/etc/transmission-rss/start.sh"]
