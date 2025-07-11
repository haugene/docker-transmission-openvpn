### Web proxy configuration options

This container also contains a web-proxy server to allow you to tunnel your web browser traffic through the same OpenVPN tunnel.
The proxy used is [Privoxy](https://www.privoxy.org/) and is highly configurable using the built-in web interface available on [config.privoxy.org](http://config.privoxy.org) (available once your browser is correctly configured to use the localhost:8118 HTTP Proxy).
This is useful if you are using a private tracker that needs to see you log in from the same IP address you are torrenting from.
The default listening port is 8118. Note that only ports above 1024 can be specified as all ports below 1024 are privileged
and would otherwise require root permissions to run.
Remember to add a port binding for your selected (or default) port when starting the container.

| Variable                | Function                | Example                         |
| ----------------------- | ----------------------- | ------------------------------- |
| `WEBPROXY_ENABLED`      | Enables the web proxy   | `WEBPROXY_ENABLED=true`         |
| `WEBPROXY_PORT`         | Sets the listening port | `WEBPROXY_PORT=8118`            |
| `WEBPROXY_BIND_ADDRESS` | Sets the listen address | `WEBPROXY_BIND_ADDRESS=0.0.0.0` |

The listening address is the one found bound to the eth0 interface unless `WEBPROXY_BIND_ADDRESS` is set.

`adr=$(ip -4  a show eth0| grep -oP "(?<=inet )([^/]+)")`
