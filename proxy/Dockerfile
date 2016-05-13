FROM nginx

# Get curl and dockerize
RUN apt-get update \
    && apt-get install -y curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl -L https://github.com/jwilder/dockerize/releases/download/v0.2.0/dockerize-linux-amd64-v0.2.0.tar.gz | tar -C /usr/local/bin -xzv

# Set default Transmission port and copy config template
ENV TRANSMISSION_PORT=9091
COPY nginx.tmpl /etc/nginx/nginx.tmpl

# Run nginx after dockerizing config
CMD [ "dockerize", "-template", "/etc/nginx/nginx.tmpl:/etc/nginx/nginx.conf", "nginx", "-g", "daemon off;" ]