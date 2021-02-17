
* [The container runs, but I can't access the web ui](#the_container_runs_but_i_cant_access_the_web_ui)
* [How do I verify that my traffic is using VPN](#how_do_i_verify_that_my_traffic_is_using_vpn)
* [RTNETLINK answers: File exists](#rtnetlink_answers_file_exists)
* [RTNETLINK answers: Invalid argument](#rtnetlink_answers_invalid_argument)
* [TUNSETIFF tun: Operation not permitted](#tunsetiff_tun_operation_not_permitted)
* [Error resolving host address](#error_resolving_host_address)
* [Container loses connection after some time](#container_loses_connection_after_some_time)
  * [Set the ping-exit option for OpenVPN and restart-flag in Docker](#set_the_ping-exit_option_for_openvpn_and_restart-flag_in_docker)
  * [Use a third party tool to monitor and restart the container](#use_a_third_party_tool_to_monitor_and_restart_the_container)
* [AUTH: Received control message: AUTH_FAILED](#auth_received_control_message_auth_failed)

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

## RTNETLINK answers: Invalid argument

This can occur because you have specified an invalid **subnet** or possibly specified an IP Address in CIDR format instead of a subnet. Your LOCAL_NETWORK property must be aimed at a **subnet** and not at an IP Address. 

A valid example would be

     ```
     LOCAL_NETWORK=10.80.0.0/24
     ```

but an invalid target route that would cause this error might be 

     ```
     #Invalid because the subnet for this range would be 10.20.30.0/24
     LOCAL_NETWORK=10.20.30.45/24
     ```

To check your value, you can use a [subnet calculator](https://www.calculator.net/ip-subnet-calculator.html). 
* Enter your IP Address - the portion before the mask, `10.20.30.45` here
* select the subnet that matches - the `/24` portion here
* Take the Network Address that is returned - `10.20.30.0` in this case 

## TUNSETIFF tun: Operation not permitted

This is usually a question of permissions. Have you set the [NET_ADMIN capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) to the container? What if you use `docker run --privileged`, do you still get that error?

This is an error where we haven't got too much information. If the hints above get you nowhere, create an issue.

## Error resolving host address

This error can happen multiple places in the scripts. The most common is that it happens with `curl` trying to download the latest .ovpn
config bundle for those providers that has an update script, or that OpenVPN throws the error when trying to connect to the VPN server.

The curl error looks something like `curl: (6) Could not resolve host: ...` and OpenVPN says `RESOLVE: Cannot resolve host address: ...`.
Either way the problem is that your container does not have a valid DNS setup. We have two recommended ways of addressing this.

The first solution is to use the `dns` option offered by Docker. This is available in
[Docker run](https://docs.docker.com/engine/reference/run/#network-settings) as well as
[Docker Compose](https://docs.docker.com/compose/compose-file/#dns). You can add `--dns 8.8.8.8 --dns 8.8.4.4` to use Google DNS servers.
Or add the corresponding block in docker-compose.yml:
```
  dns:
    - 8.8.8.8
    - 8.8.4.4
```
You can of course use any DNS servers you want here. Google servers are popular. So is Cloudflare DNS.

The second approach is to use some environment variables to override `/etc/resolv.conf` in the container.
Using the same DNS servers as in the previous approach you can set:
```
OVERRIDE_DNS_1=8.8.8.8
OVERRIDE_DNS_2=8.8.4.4
```

This will be read by the startup script and it will override the contents of `/etc/resolv.conf` accordingly. You can have one
or more of these servers and they will be sorted alphabetically.

**What is the difference between these solutions?**

A good question as they both seem to override what DNS servers the container should use. However they are not equal.

The first solution uses the dns flags from Docker. This will mean that we instruct Docker to use these DNS servers for the container,
but the resolv.conf file in the container will still point to the Docker DNS service. Docker might have many reasons for this but one of
them is at least for service discovery. If you're running your container as a part of a larger docker-compose file or custom docker network
and you want to be able to lookup the other containers based on their service names then you need to use the Docker DNS service.
By using the `--dns` flags you should have both control of what DNS servers are used for external requests as well as container DNS lookup.

The second solution is more direct. It rewrites the resolv.conf file so that it no longer refers to the Docker DNS service.
The effects of this is that you lose Docker service discovery from the container (other containers in the same network can still resolve it)
but you have cut out a middleman and potential point of error. I'm not sure why this some times is necessary but it has proven to fix
the issue in some cases.

**A possible third option**

If you're facing the OpenVPN error (not curl) then your provider might have config files with IP addresses instead of DNS.
That way your container won't need DNS to do a lookup for the server. Note that the trackers will still need DNS, so this will only
solve the problem for you if it is your local network that in some way is blocking the DNS.


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

**NOTE** Some providers have multiple sets of credentials. Some for OpenVPN, others for web login, proxy solutions, etc.
Make sure that you use the ones intended for OpenVPN. **PIA users:** this has recently changed. It used to be a separate pair, but now
you should use the same login as you do in the web control panel. Before you were supposed to use a username like x12345, now its the p12345 one. There is also a 99 character limit on password length.

First check that your credentials are correct. Some providers have separate credentials for OpenVPN so it might not be the same as for their apps.
Secondly, test a few different servers just to make sure that it's not just a faulty server. If this doesn't resolve it, it's probably the container.

To verify this you can mount a volume to `/config` in the container. So for example `/temporary/folder:/config`. Your credentials will be written to
`/config/openvpn-credentials.txt` when the container starts, more on that [here](building-blocks.md#starting_openvpn). So by mounting this folder
you will be able to check the contents of that text file. The first line should be your username, the second should be your password.

This file is what's passed to OpenVPN. If your username/password is correct here then you should probably contact your provider.
