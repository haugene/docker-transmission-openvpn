FROM ruby:2-alpine

# Image caching, put "never changing" layers first
CMD ["/etc/transmission-rss/start.sh"]
ENV TRANSMISSION_DOWNLOAD_DIR=/data/completed \
    RSS_URL=**None** \
    RSS_REGEXP=

# Install build-base and transmission-rss gem
RUN apk add build-base bash && gem install transmission-rss

ADD . /etc/transmission-rss
