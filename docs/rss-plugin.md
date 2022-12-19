The Transmission RSS plugin can optionally be run as a separate container. It allows downloading torrents based on an RSS URL, see [Plugin page](https://github.com/nning/transmission-rss).

```
$ docker run -d \
      -e "RSS_URL=<URL>" \
      --link <transmission-container>:transmission \
      --name "transmission-rss" \
      haugene/transmission-rss
```
At first start a transmission-rss.conf file will be created in /etc if no manual one is mounted
A manual transmission-rss.conf file can be mounted into the container to add additional parameters, e.g. login details to rpc
example:
```
$ docker run -d \
      -v <transmission-rss.conf>:/etc/transmission-rss.conf \
      --link <transmission-container>:transmission \
      --name "transmission-rss" \
      haugene/transmission-rss
```

transmission-rss.conf example

```
feeds:
  - url: <placeholder>
    download_path: <placeholder>
    regexp: <placeholder>
    
server:
  host: transmission
  port: 9091
  rpc_path: /transmission/rpc

login:
  username: <username>
  password: <password>

```
