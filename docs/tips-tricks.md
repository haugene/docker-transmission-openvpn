#### Use Google DNS servers
Some have encountered problems with DNS resolving inside the docker container.
This causes trouble because OpenVPN will not be able to resolve the host to connect to.
If you have this problem use Docker's --dns flag and try using Google's DNS servers by
adding --dns 8.8.8.8 --dns 8.8.4.4 as parameters to the usual run command.

#### Restart container if connection is lost
If the VPN connection fails or the container for any other reason loses connectivity, you want it to recover from it. One way of doing this is to set environment variable `OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60` and use the --restart=always flag when starting the container. This way OpenVPN will exit if ping fails over a period of time which will stop the container and then the Docker deamon will restart it.

#### Let other containers use VPN

[TODO](https://github.com/haugene/docker-transmission-openvpn/issues/1558): Relevant issues...

#### Reach sleep or hybernation on your host if no torrents are active
By befault Transmission will always [scrape](https://en.wikipedia.org/wiki/Tracker_scrape) trackers, even if all torrents have completed their activities, or they have been paused manually. This will cause Transmission to be always active, therefore never allow your host server to be inactive and go to sleep/hybernation/whatever. If this is something you want, you can add the following variable when creating the container. It will turn off a hidden setting in Tranmsission which will stop the application to scrape trackers for paused torrents. Transmission will become inactive, and your host will reach the desidered state.
```
-e "TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED=false"
```

#### Running it on a NAS
Several popular NAS platforms supports Docker containers. You should be able to set up
and configure this container using their web interfaces. As of version 3.0 of this image
creates a TUN interface inside the container by default. This previously had to be mounted
from the host which was an issue for some NAS servers. The assumption is that this should
now be fixed. If you have issues and the logs seem to blame "/dev/net/tun" in some way
then you might consider trying to mount a host device and see if that works better.
Setting up a TUN device is probably easiest to accomplish by installing an OpenVPN package
for the NAS. This should set up the device and you can mount it.
There are some issues involved running it on Synology NAS, 
Please see following issue that discusses [solutions](https://github.com/haugene/docker-transmission-openvpn/issues/1542#issuecomment-793605649)

#### Systemd Integration
On many modern linux systems, including Ubuntu, systemd can be used to start the transmission-openvpn at boot time, and restart it after any failure.

Save the following as `/etc/systemd/system/transmission-openvpn.service`, and replace the OpenVPN PROVIDER/USERNAME/PASSWORD directives with your settings, and add any other directives that you're using.

This service is assuming that there is a `bittorrent` user set up with a home directory at `/home/bittorrent/`. The data directory will be mounted at `/home/bittorrent/data/`. This can be changed to whichever user and location you're using.

OpenVPN is set to exit if there is a connection failure. OpenVPN exiting triggers the container to also exit, then the `Restart=always` definition in the `transmission-openvpn.service` file tells systems to restart things again.

```
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

```
$ sudo systemctl enable /etc/systemd/system/transmission-openvpn.service
$ sudo systemctl restart transmission-openvpn.service
```

If it is stopped or killed in any fashion, systemd will restart the container. If you do want to shut it down, then run the following command and it will stay down until you restart it.

```
$ sudo systemctl stop transmission-openvpn.service
# Later ...
$ sudo systemctl start transmission-openvpn.service
```
