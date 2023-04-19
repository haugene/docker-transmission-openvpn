### Required environment options

| Variable           | Function                          | Example                                                                                                 |
| ------------------ | --------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `OPENVPN_PROVIDER` | Sets the OpenVPN provider to use. | `OPENVPN_PROVIDER=provider`. Supported providers and their config values are listed in the table above. |
| `OPENVPN_USERNAME` | Your OpenVPN username             | `OPENVPN_USERNAME=asdf`                                                                                 |
| `OPENVPN_PASSWORD` | Your OpenVPN password, beware of special characters. Docker run vs docker-compose (using YAML) interpret special characters differently, see  [Yaml special characters](https://support.asg.com/mob/mvw/10_0/mv_ag/using_quotes_with_yaml_special_characters.htm)             | `OPENVPN_PASSWORD=asdf`                                                                                 |

Docker secrets are available to define OPENVPN_USER and OPENVPN_PASSWORD.

* remove OPENVPN_USERNAME, OPENVPN_PASSWORD from environment.
* write your credentials in one file: openvpn_creds
* add to your compose YAML:

```yaml
version: '3.8'
services:
 transmission:
    ....
    secrets:
        - openvpn_creds

secrets:
    openvpn_creds:
        file: ./openvpn_creds
```

### Network configuration options

| Variable            | Function                                                                                            | Example                                                                                                        |
| ------------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `OPENVPN_CONFIG`    | Sets the OpenVPN endpoint to connect to.                                                            | `OPENVPN_CONFIG=UK Southampton`                                                                                |
| `OPENVPN_OPTS`      | Will be passed to OpenVPN on startup                                                                | See [OpenVPN doc](https://openvpn.net/index.php/open-source/documentation/manuals/65-openvpn-20x-manpage.html) |
| `LOCAL_NETWORK`     | Sets the local network that should have access. Accepts comma-separated list.                       | `LOCAL_NETWORK=192.168.0.0/24`                                                                                 |
| `CREATE_TUN_DEVICE` | Creates /dev/net/tun device inside the container, mitigates the need to mount the device from the host | `CREATE_TUN_DEVICE=true`                                                                                       |
| `PEER_DNS`          | Controls whether to use the DNS provided by the OpenVPN endpoint. | To use your host DNS rather than what is provided by OpenVPN, set `PEER_DNS=false`.  This allows for potential DNS leakage. |
| `PEER_DNS_PIN_ROUTES` | Controls whether to force traffic to peer DNS through the OpenVPN tunnel. | To disable this default, set `PEER_DNS_PIN_ROUTES=false`. |

### Timezone option

Set a custom timezone in tz database format. Look [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for a list of valid timezones. Defaults to UTC.

| Variable | Function     | Example  |
| -------- | ------------ | -------- |
| `TZ`     | Set Timezone | `TZ=UTC` |

### Firewall configuration options

When enabled, the firewall blocks everything except traffic to the peer port and traffic to the rpc port from the LOCAL_NETWORK and the internal docker gateway.

If TRANSMISSION_PEER_PORT_RANDOM_ON_START is enabled then it allows traffic to the range of peer ports defined by TRANSMISSION_PEER_PORT_RANDOM_HIGH and TRANSMISSION_PEER_PORT_RANDOM_LOW.

| Variable                      | Function                                                                                                                    | Example                            |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `ENABLE_UFW`                  | Enables the firewall                                                                                                        | `ENABLE_UFW=true`                  |
| `UFW_ALLOW_GW_NET`            | Allows the gateway network through the firewall. Off defaults to only allowing the gateway.                                 | `UFW_ALLOW_GW_NET=true`            |
| `UFW_EXTRA_PORTS`             | Allows the comma-separated list of ports through the firewall. Respects UFW_ALLOW_GW_NET.                                   | `UFW_EXTRA_PORTS=9910,23561,443`   |
| `UFW_DISABLE_IPTABLES_REJECT` | Prevents the use of `REJECT` in the `iptables` rules, for hosts without the `ipt_REJECT` module (such as the Synology NAS). | `UFW_DISABLE_IPTABLES_REJECT=true` |

### Health check option

Because your VPN connection can sometimes fail, Docker will run a health check on this container every 5 minutes to see if the container is still connected to the internet. By default, this check is done by pinging google.com once. You change the host that is pinged.

| Variable            | Function                                                           | Example      |
| ------------------- | ------------------------------------------------------------------ | ------------ |
| `HEALTH_CHECK_HOST` | this host is pinged to check if the network connection still works | `google.com` |

### Permission configuration options

By default, the startup script applies a default set of permissions and ownership on the transmission download, watch and incomplete directories. The GLOBAL_APPLY_PERMISSIONS directive can be used to disable this functionality.

| Variable                   | Function                               | Example                          |
| -------------------------- | -------------------------------------- | -------------------------------- |
| `GLOBAL_APPLY_PERMISSIONS` | Disable setting of default permissions | `GLOBAL_APPLY_PERMISSIONS=false` |

### Alternative Web UIs

This container comes bundled with some alternative Web UIs:

* [Combustion UI](https://github.com/Secretmapper/combustion)
* [Kettu](https://github.com/endor/kettu)
* [Transmission-Web-Control](https://github.com/ronggang/transmission-web-control/)
* [Flood for Transmission](https://github.com/johman10/flood-for-transmission)
* [Shift](https://github.com/killemov/Shift)
* [Transmissionic](https://github.com/6c65726f79/Transmissionic)

To use one of them instead of the default Transmission UI you can set `TRANSMISSION_WEB_UI`
to either `combustion`, `kettu`, `transmission-web-control`, `flood-for-transmission`, `shift` or `transmissionic` respectively.

| Variable                | Function                         | Example                                                                                                                                       |
| ----------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `TRANSMISSION_WEB_UI`   | Use the specified bundled web UI | `TRANSMISSION_WEB_UI=combustion` <br>`TRANSMISSION_WEB_UI=kettu` <br>`TRANSMISSION_WEB_UI=transmission-web-control` <br>`TRANSMISSION_WEB_UI=flood-for-transmission` <br>`TRANSMISSION_WEB_UI=shift` <br>`TRANSMISSION_WEB_UI=transmissionic` |

### User configuration options

By default, everything will run as the root user. However, it is possible to change who runs the transmission process.
You may set the following parameters to customize the user id that runs Transmission.

| Variable | Function                                    | Example     |
| -------- | ------------------------------------------- | ----------- |
| `PUID`   | Sets the user id who will run transmission  | `PUID=1003` |
| `PGID`   | Sets the group id for the transmission user | `PGID=1003` |

### Transmission configuration options

In previous versions of this container the settings were not persistent but were generated from environment variables on container startup.
This had the benefit of being very explicit and reproducible but you had to provide Transmission config as environment variables if you
wanted them to stay that way between container restarts. This felt cumbersome to many.

As of version 4.2, this is no longer true. Settings are now persisted in the `/config/transmission-home` folder in the container and as
long as you mount `/config` you should be able to configure Transmission using the UI as you normally would.
If you are using the container from earlier versions and have not changed the location of transmission-home to /config, you will see a warning message that the default has changed.
You can manually move the folder to your /config volume directory after stopping the container and adding the /config mount to your container setup (compose/run etc).

You may still override Transmission options by setting environment variables if that's your thing.
The variables are named after the transmission config they target but are prefixed with `TRANSMISSION_`, capitalized, and `-` is converted to `_`.

For example:

| Transmission variable name   | Environment variable name                 |
|------------------------------|-------------------------------------------|
| `speed-limit-up`             | `TRANSMISSION_SPEED_LIMIT_UP`             |
| `speed-limit-up-enabled`     | `TRANSMISSION_SPEED_LIMIT_UP_ENABLED`     |
| `ratio-limit`                | `TRANSMISSION_RATIO_LIMIT`                |
| `ratio-limit-enabled`        | `TRANSMISSION_RATIO_LIMIT_ENABLED`        |

A full list of variables can be found in the Transmission documentation [here](https://github.com/transmission/transmission/blob/main/docs/Editing-Configuration-Files.md#options).

All variables overridden by environment variables will be logged during startup.

PS: `TRANSMISSION_BIND_ADDRESS_IPV4` will automatically be overridden to the IP assigned to your OpenVPN tunnel interface.
This ensures that Transmission only listens for torrent traffic on the VPN interface and is part of the fail-safe mechanisms.

### Dropping default route from iptables (advanced)

Some VPNs do not override the default route, but rather set other routes with a lower metric.
This might lead to the default route (your untunneled connection) being used.

To drop the default route set the environment variable `DROP_DEFAULT_ROUTE` to `true`.

_Note_: This is not compatible with all VPNs. You can check your iptables routing with the `ip r` command in a running container.

### Changing logging locations

By default, Transmission will log to a file in `TRANSMISSION_HOME/transmission.log`.

To log to stdout instead set the environment variable `LOG_TO_STDOUT` to `true`.

_Note_: By default, stdout is what container engines read logs from. Set this to true to have Transmission logs in commands like `docker logs` and `kubectl logs`. OpenVPN currently only logs to stdout.

### Custom scripts

If you ever need to run custom code before or after Transmission is executed or stopped, you can use the custom scripts feature.
Custom scripts are located in the `/scripts` directory which is empty by default.
To enable this feature, you'll need to mount the `/scripts` directory.

Once `/scripts` is mounted you'll need to write your custom code in the following bash shell scripts:

| Script                              | Function                                                     |
| ----------------------------------- | ------------------------------------------------------------ |
| /scripts/openvpn-pre-start.sh       | This shell script will be executed before OpenVPN starts      |
| /scripts/openvpn-post-config.sh     | This shell script will be executed after OpenVPN config      |
| /scripts/transmission-pre-start.sh  | This shell script will be executed before transmission starts |
| /scripts/transmission-post-start.sh | This shell script will be executed after transmission starts |
| /scripts/routes-post-start.sh       | This shell script will be executed after routes are added    |
| /scripts/transmission-pre-stop.sh   | This shell script will be executed before transmission stops  |
| /scripts/transmission-post-stop.sh  | This shell script will be executed after transmission stops   |

Don't forget to include the `#!/bin/bash` shebang and to make the scripts executable using `chmod a+x`

### Debugging

By default, commands are not echoed to stdout before being processed. Setting DEBUG to any value other than the string false will trigger command echo (set -x) for all bash scripts.

| Variable                              | Function |Example|
| ----------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
|DEBUG|Echo all commands to stdout.|DEBUG=true|
