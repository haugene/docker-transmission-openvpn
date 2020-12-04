
* [The container runs, but I can't access the web ui](#the_container_runs_but_i_cant_access_the_web_ui)
* [How do I verify that my traffic is using VPN](#how_do_i_verify_that_my_traffic_is_using_vpn)
* [RTNETLINK answers: File exists](#rtnetlink_answers_file_exists)
* [TUNSETIFF tun: Operation not permitted](#tunsetiff_tun_operation_not_permitted)
* [AUTH: Received control message: AUTH_FAILED](#auth_received_control_message_auth_failed)
* [Container loses connection after some time](#container_loses_connection_after_some_time)

## The container runs, but I can't access the web ui

[TODO](https://github.com/haugene/docker-transmission-openvpn/issues/1558): Short explanation and link to [networking](vpn-networking.md)

## How do I verify that my traffic is using VPN

There are many ways of doing this, and I welcome you to add to this list if you have any suggestsions.

You can exec into the container and throug the shell use `curl` to ask for your public IP. There are
multiple endpoints for this but here are a few suggestions:

* `curl http://ipinfo.io/ip`
* `curl http://ipecho.net/plain`
* `curl icanhazip.com`

Or you could use a test torrent service to download a torrent file and then you can get the IP from that tracker.

* http://ipmagnet.services.cbcdn.com/
* https://torguard.net/checkmytorrentipaddress.php

## RTNETLINK answers: File exists

[TODO](https://github.com/haugene/docker-transmission-openvpn/issues/1558): Conflicting LOCAL_NETWORK values. Short explanation and link to [networking](vpn-networking.md)


## TUNSETIFF tun: Operation not permitted

This is usually a question of permissions. Have you set the [NET_ADMIN capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) to the container? What if you use `docker run --privileged`, do you still get that error?

This is an error where we haven't got too much information. If the hints above get you nowhere, create an issue.


## Container loses connection after some time

For some users, on some platforms, apparently this is an issue. I have not encountered this myself - but there is no doubt that it's recurring.
Why does the container lose connectivity? That we don't know and it could be many different reasons that manifest the same symptoms.
We do however have some possible solutions.

### Set the ping-exit option for OpenVPN and restart-flag in Docker

Most provider configs have a ping-restart option set. So if the tunnel fails, OpenVPN will restart and re-connect. That works well on regular systems.
The problem is that if the container has lost internet connection restarting OpenVPN will not fix anything. What you can do though is to set/override
this option using `OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60`. This will tell OpenVPN to exit when it cannot ping the server for 1 minute.

When OpenVPN exits, the container will exit. And if you've then set `restart=always` or `restart=unless-stopped` in your Docker config then Docker will
restart the container and that could/should restore connectivity. VPN providers sometime push options to their clients after they connect. This is visible
in the logs if they do. If they push ping-restart that can override your settings. So you could consider adding `--pull-filter ignore ping` to the options above.

This approach will probably work, especially if you're seeing logs like these from before:
```
Inactivity timeout (--ping-restart), restarting
SIGUSR1[soft,ping-restart] received, process restarting
```

### Use a third party tool to monitor and restart the container

The container has a health check script that is run periodically. It will report the health status to Docker and the container will show as "unhealthy"
if basic network connectivity is broken. You can write your own script and add it to cron, or you can use a tool like [https://github.com/willfarrell/docker-autoheal](https://github.com/willfarrell/docker-autoheal) to look for and restart unhealthy containers.

This container has the `autoheal` label by default so it is compatible with the [willfarrell/autoheal image](https://hub.docker.com/r/willfarrell/autoheal/)

## AUTH: Received control message: AUTH_FAILED

If your logs end like this, the wrong username/password was sent to your VPN provider.
```
AUTH: Received control message: AUTH_FAILED
SIGTERM[soft,auth-failure] received, process exiting
```

We can divide the possible errors here into three. You have entered the wrong credentials, the server has some kind of error or the container has messed
up your credentials. We have had challenges with special characters. Having "?= as part of your password has tripped up our scripts from time to time.

First check that your credentials are correct. Some providers have separate credentials for OpenVPN so it might not be the same as for their apps.
Secondly, test a few different servers just to make sure that it's not just a faulty server. If this doesn't resolve it, it's probably the container.

To verify this you can mount a volume to `/config` in the container. So for example `/temporary/folder:/config`. Your credentials will be written to
`/config/openvpn-credentials.txt` when the container starts, more on that [here](building-blocks.md#starting_openvpn). So by mounting this folder
you will be able to check the contents of that text file. The first line should be your username, the second should be your password.

This file is what's passed to OpenVPN. If your username/password is correct here than you should probably contact your provider.
