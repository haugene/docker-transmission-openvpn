# Use Google DNS servers
Some have encountered problems with DNS resolving inside the docker container.
This causes trouble because OpenVPN will not be able to resolve the host to connect to.
If you have this problem use Docker's --dns flag and try using Google's DNS servers by
adding --dns 8.8.8.8 --dns 8.8.4.4 as parameters to the usual run command.

# Restart the container if the connection is lost
If the VPN connection fails or the container for any other reason loses connectivity, you want it to recover from it. One way of doing this is to set the environment variable `OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60` and use the --restart=always flag when starting the container. This way OpenVPN will exit if ping fails over a period of time which will stop the container and then the Docker daemon will restart it.

# Let other containers use the VPN

To let other containers use VPN you have to add them to the same Service network as your VPN container runs, you can do this by adding `network_mode: "service:transmission-openvpn"`. Additionally, you have to set `depends_on` to the `transmission-openvpn` service to let docker-compose know that your new container should start **after** `transmission-openvpn` is up and running. As the final step, you can add `healthcheck` to your service.

## Example (Jackett):
As an example, let's add [Jackett](https://github.com/linuxserver/docker-jackett) to the `transmission-openvpn` network based on the example from [Running the container](run-container.md):

```yaml
version: '3.3'
services:
    transmission-openvpn:
        cap_add:
            - NET_ADMIN
        volumes:
            - '/your/storage/path/:/data'
        environment:
            - OPENVPN_PROVIDER=PIA
            - OPENVPN_CONFIG=france
            - OPENVPN_USERNAME=user
            - OPENVPN_PASSWORD=pass
            - LOCAL_NETWORK=192.168.0.0/16
        logging:
            driver: json-file
            options:
                max-size: 10m
        ports:
            - '9091:9091'
            - '9117:9117'  # This is Jackett Port – managed by VPN Service Network
        image: haugene/transmission-openvpn
    jackett:
        image: lscr.io/linuxserver/jackett:latest
        container_name: jackett
        environment:
            - PUID=1000
            - PGID=1000
            - TZ=Europe/London
            - AUTO_UPDATE=true #optional
            - RUN_OPTS=<run options here> #optional
        volumes:
            - <path to data>:/config
            - <path to blackhole>:/downloads
        # You have to comment ports, they should be managed in transmission-openvpn section now.
#       ports:
#           - 9117:9117
        restart: unless-stopped
        network_mode: "service:transmission-openvpn" # Add to the transmission-openvpn Container Network
        depends_on:
            - transmission-openvpn # Set dependency on transmission-openvpn Container
        healthcheck: # Here you will check if transmission is reachable from the Jackett container via localhost
            test: curl -f http://localhost:9091 || exit 1
            # Use this test if you protect your transmission with a username and password 
            # comment the test above and un-comment the line below.
            #test: curl -f http://${TRANSMISSION_RPC_USERNAME}:${TRANSMISSION_RPC_PASSWORD}@localhost:9091 || exit 1
            interval: 5m00s
            timeout: 10s
            retries: 2
```

### Check if the container is using VPN

After the container starts, simply call `curl` under it to check your IP address, for example with Jackett you should see your VPN IP address as output:

```bash
docker exec jackett curl -s https://api.ipify.org
```

You can also check that Jackett is attached to the VPN network by pinging it from the `transmission-openvpn` Container `localhost`:

```bash
docker exec transmission-vpn curl -Is http://localhost:9117
HTTP/1.1 301 Moved Permanently
Date: Tue, 17 May 2022 19:58:19 GMT
Server: Kestrel
Location: /UI/Dashboard
```

## Example (Dante):
As an example, let's add [Dante](https://www.inet.no/dante/) socks5 proxy to the `transmission-openvpn` network based on the example from [Running the container](run-container.md):

```yaml
version: '3.3'
services:
    transmission-openvpn:
        cap_add:
            - NET_ADMIN
        volumes:
            - '/your/storage/path/:/data'
        environment:
            - OPENVPN_PROVIDER=PIA
            - OPENVPN_CONFIG=france
            - OPENVPN_USERNAME=user
            - OPENVPN_PASSWORD=pass
            - LOCAL_NETWORK=192.168.0.0/16
        logging:
            driver: json-file
            options:
                max-size: 10m
        ports:
            - '9091:9091'
            - '1080:1080'  # This is Dante Socks5 Port – managed by VPN Service Network
        restart: unless-stopped
        image: haugene/transmission-openvpn

    socks5-proxy:
        image: wernight/dante
        restart: unless-stopped
        network_mode: service:transmission-openvpn
        depends_on:
            - transmission-openvpn
        command:
            - /bin/sh
            - -c
            - |
                echo "Waiting for VPN to connect . . ."
                while ! ip link show tun0 >/dev/null 2>&1 || ! ip link show tun0 | grep -q "UP"; do sleep 1; done
                echo "VPN connected. Starting proxy service . . ."
                sed -i 's/^\(external:\).*/\1 tun0/' /etc/sockd.conf
                sockd
```

### Test Dante socks5 proxy
```bash
curl -x socks5h://{docker-host-ip}:1080 http://ip.ip-check.net
```

### Bonus socks5 tip
With the [Proxy SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif) Chrome/Edge extension, you can configure specific websites on your local machine to route through your socks5 proxy server.

# Reach sleep or hibernation on your host if no torrents are active
By default, Transmission will always [scrape](https://en.wikipedia.org/wiki/Tracker_scrape) trackers, even if all torrents have completed their activities, or they have been paused manually. This will cause Transmission to be always active, therefore never allow your host server to be inactive and go to sleep/hibernation/whatever. If this is something you want, you can add the following variable when creating the container. It will turn off a hidden setting in Transmission which will stop the application to scrape trackers for paused torrents. Transmission will become inactive, and your host will reach the desired state.
```bash
-e "TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED=false"
```

# Running it on a NAS
Several popular NAS platforms support Docker containers. You should be able to set up
and configure this container using their web interfaces. As of version 3.0 of this image
creates a TUN interface inside the container by default. This previously had to be mounted
from the host which was an issue for some NAS servers. The assumption is that this should
now be fixed. If you have issues and the logs seem to blame "/dev/net/tun" in some way
then you might consider trying to mount a host device and see if that works better.
Setting up a TUN device is probably easiest to accomplish by installing an OpenVPN package
for the NAS. This should set up the device and you can mount it.
There are some issues involved in running it on Synology NAS, 
Please see this issue that discusses [solutions](https://github.com/haugene/docker-transmission-openvpn/issues/1542#issuecomment-793605649)

# Systemd Integration
On many modern Linux systems, including Ubuntu, systemd can be used to start the transmission-openvpn at boot time, and restart it after any failure.

Save the following as `/etc/systemd/system/transmission-openvpn.service`, and replace the OpenVPN PROVIDER/USERNAME/PASSWORD directives with your settings, and add any other directives that you're using.

This service is assuming that there is a `bittorrent` user set up with a home directory at `/home/bittorrent/`. The data directory will be mounted at `/home/bittorrent/data/`. This can be changed to whichever user and location you're using.

OpenVPN is set to exit if there is a connection failure. OpenVPN exiting triggers the container to also exit, and then the `Restart=always` definition in the `transmission-openvpn.service` file tells systems to restart things again.

```bash
[Unit]
Description=haugene/transmission-openvpn docker container
After=docker.service
Requires=docker.service

[Service]
User=bittorrent
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill transmission-openvpn
ExecStartPre=-/usr/bin/docker rm transmission-openvpn
ExecStartPre=/usr/bin/docker pull haugene/transmission-openvpn
ExecStart=/usr/bin/docker run \
        --name transmission-openvpn \
        --cap-add=NET_ADMIN \
        -v /home/bittorrent/data/:/data \
        -e "OPENVPN_PROVIDER=TORGUARD" \
        -e "OPENVPN_USERNAME=bittorrent@example.com" \
        -e "OPENVPN_PASSWORD=hunter2" \
        -e "OPENVPN_CONFIG=CA Toronto" \
        -e "OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60" \
        -p 9091:9091 \
        --dns 8.8.8.8 \
        --dns 8.8.4.4 \
        haugene/transmission-openvpn
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Then enable and start the new service with:

```bash
$ sudo systemctl enable /etc/systemd/system/transmission-openvpn.service
$ sudo systemctl restart transmission-openvpn.service
```

If it is stopped or killed in any fashion, systemd will restart the container. If you do want to shut it down, then run the following command and it will stay down until you restart it.

```bash
$ sudo systemctl stop transmission-openvpn.service
# Later ...
$ sudo systemctl start transmission-openvpn.service
```
# Running with Traefik reverse proxy

A working example of running this container behind a traefik reverse proxy can be found here:
[Config](https://github.com/haugene/docker-transmission-openvpn/issues/1763#issuecomment-844404143)

#### Running this container with Podman

The `podman run` command is almost identical to [the one mentioned in README.md](../README.md#docker-run) but with the following exception:

Instead `--cap-add=NET_ADMIN` you have to specify `--cap-add=NET_ADMIN,NET_RAW,MKNOD`. `MKNOD` and `NET_ADMIN` are necessary so Podman can create the tunnel, `NET_RAW` is needed for `ping`.
