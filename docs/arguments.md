### Required environment options
| Variable           | Function                          | Example                                                                                                 |
| ------------------ | --------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `OPENVPN_PROVIDER` | Sets the OpenVPN provider to use. | `OPENVPN_PROVIDER=provider`. Supported providers and their config values are listed in the table above. |
| `OPENVPN_USERNAME` | Your OpenVPN username             | `OPENVPN_USERNAME=asdf`                                                                                 |
| `OPENVPN_PASSWORD` | Your OpenVPN password             | `OPENVPN_PASSWORD=asdf`                                                                                 |

### Network configuration options
| Variable            | Function                                                                                            | Example                                                                                                        |
| ------------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `OPENVPN_CONFIG`    | Sets the OpenVPN endpoint to connect to.                                                            | `OPENVPN_CONFIG=UK Southampton`                                                                                |
| `OPENVPN_OPTS`      | Will be passed to OpenVPN on startup                                                                | See [OpenVPN doc](https://openvpn.net/index.php/open-source/documentation/manuals/65-openvpn-20x-manpage.html) |
| `LOCAL_NETWORK`     | Sets the local network that should have access. Accepts comma separated list.                       | `LOCAL_NETWORK=192.168.0.0/24`                                                                                 |
| `CREATE_TUN_DEVICE` | Creates /dev/net/tun device inside the container, mitigates the need mount the device from the host | `CREATE_TUN_DEVICE=true`                                                                                       |

### Firewall configuration options
When enabled, the firewall blocks everything except traffic to the peer port and traffic to the rpc port from the LOCAL_NETWORK and the internal docker gateway.

If TRANSMISSION_PEER_PORT_RANDOM_ON_START is enabled then it allows traffic to the range of peer ports defined by TRANSMISSION_PEER_PORT_RANDOM_HIGH and TRANSMISSION_PEER_PORT_RANDOM_LOW.

| Variable                      | Function                                                                                                                    | Example                            |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `ENABLE_UFW`                  | Enables the firewall                                                                                                        | `ENABLE_UFW=true`                  |
| `UFW_ALLOW_GW_NET`            | Allows the gateway network through the firewall. Off defaults to only allowing the gateway.                                 | `UFW_ALLOW_GW_NET=true`            |
| `UFW_EXTRA_PORTS`             | Allows the comma separated list of ports through the firewall. Respects UFW_ALLOW_GW_NET.                                   | `UFW_EXTRA_PORTS=9910,23561,443`   |
| `UFW_DISABLE_IPTABLES_REJECT` | Prevents the use of `REJECT` in the `iptables` rules, for hosts without the `ipt_REJECT` module (such as the Synology NAS). | `UFW_DISABLE_IPTABLES_REJECT=true` |

### Health check option

Because your VPN connection can sometimes fail, Docker will run a health check on this container every 5 minutes to see if the container is still connected to the internet. By default, this check is done by pinging google.com once. You change the host that is pinged.

| Variable            | Function                                                           | Example      |
| ------------------- | ------------------------------------------------------------------ | ------------ |
| `HEALTH_CHECK_HOST` | this host is pinged to check if the network connection still works | `google.com` |

### Permission configuration options
By default the startup script applies a default set of permissions and ownership on the transmission download, watch and incomplete directories. The GLOBAL_APPLY_PERMISSIONS directive can be used to disable this functionality.

| Variable                   | Function                               | Example                          |
| -------------------------- | -------------------------------------- | -------------------------------- |
| `GLOBAL_APPLY_PERMISSIONS` | Disable setting of default permissions | `GLOBAL_APPLY_PERMISSIONS=false` |

### Alternative web UIs
You can override the default web UI by setting the ```TRANSMISSION_WEB_HOME``` environment variable. If set, Transmission will look there for the Web Interface files, such as the javascript, html, and graphics files.

[Combustion UI](https://github.com/Secretmapper/combustion), [Kettu](https://github.com/endor/kettu) and [Transmission-Web-Control](https://github.com/ronggang/transmission-web-control/) come bundled with the container. You can enable either of them by setting```TRANSMISSION_WEB_UI=combustion```, ```TRANSMISSION_WEB_UI=kettu``` or ```TRANSMISSION_WEB_UI=transmission-web-control```, respectively. Note that this will override the ```TRANSMISSION_WEB_HOME``` variable if set.

| Variable                | Function                         | Example                                                                                                         |
| ----------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `TRANSMISSION_WEB_HOME` | Set Transmission web home        | `TRANSMISSION_WEB_HOME=/path/to/web/ui`                                                                         |
| `TRANSMISSION_WEB_UI`   | Use the specified bundled web UI | `TRANSMISSION_WEB_UI=combustion`, `TRANSMISSION_WEB_UI=kettu` or `TRANSMISSION_WEB_UI=transmission-web-control` |

### Transmission configuration options

You may override Transmission options by setting the appropriate environment variable.

The environment variables are the same name as used in the transmission settings.json file
and follow the format given in these examples:

| Transmission variable name | Environment variable name             |
| -------------------------- | ------------------------------------- |
| `speed-limit-up`           | `TRANSMISSION_SPEED_LIMIT_UP`         |
| `speed-limit-up-enabled`   | `TRANSMISSION_SPEED_LIMIT_UP_ENABLED` |
| `ratio-limit`              | `TRANSMISSION_RATIO_LIMIT`            |
| `ratio-limit-enabled`      | `TRANSMISSION_RATIO_LIMIT_ENABLED`    |

As you can see the variables are prefixed with `TRANSMISSION_`, the variable is capitalized, and `-` is converted to `_`.

Transmission options changed in the WebUI or in settings.json will be overridden at startup and will not survive after a reboot of the container. You may want to use these variables in order to keep your preferences.

PS: `TRANSMISSION_BIND_ADDRESS_IPV4` will be overridden to the IP assigned to your OpenVPN tunnel interface.
This is to prevent leaking the host IP.

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

### User configuration options

By default everything will run as the root user. However, it is possible to change who runs the transmission process.
You may set the following parameters to customize the user id that runs transmission.

| Variable | Function                                    | Example     |
| -------- | ------------------------------------------- | ----------- |
| `PUID`   | Sets the user id who will run transmission  | `PUID=1003` |
| `PGID`   | Sets the group id for the transmission user | `PGID=1003` |

### Dropping default route from iptables (advanced)

Some VPNs do not override the default route, but rather set other routes with a lower metric.
This might lead to the default route (your untunneled connection) to be used.

To drop the default route set the environment variable `DROP_DEFAULT_ROUTE` to `true`.

*Note*: This is not compatible with all VPNs. You can check your iptables routing with the `ip r` command in a running container.
