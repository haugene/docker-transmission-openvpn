The Transmission RSS plugin can optionally be run as a separate container. It allow to download torrents based on an RSS URL, see [Plugin page](https://github.com/nning/transmission-rss).

```
$ docker run -d \
      -e "RSS_URL=<URL>" \
      --link <transmission-container>:transmission \
      --name "transmission-rss" \
      haugene/transmission-rss
```
