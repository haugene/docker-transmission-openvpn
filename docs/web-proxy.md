### Web proxy configuration options

This container also contains a web-proxy server to allow you to tunnel your web-browser traffic through the same OpenVPN tunnel.
This is useful if you are using a private tracker that needs to see you login from the same IP address you are torrenting from.
The default listening port is 8888. Note that only ports above 1024 can be specified as all ports below 1024 are privileged
and would otherwise require root permissions to run.
Remember to add a port binding for your selected (or default) port when starting the container.
If you set Username and Password it will enable BasicAuth for the proxy

| Variable           | Function                | Example                 |
| ------------------ | ----------------------- | ----------------------- |
| `WEBPROXY_ENABLED` | Enables the web proxy   | `WEBPROXY_ENABLED=true` |
| `WEBPROXY_PORT`    | Sets the listening port | `WEBPROXY_PORT=8888`    |
| `WEBPROXY_USERNAME`| Sets the BasicAuth username | `WEBPROXY_USERNAME=test`    |
| `WEBPROXY_PASSWORD`| Sets the BasicAuth password  | `WEBPROXY_PASSWORD=password`    |