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
        --device=/dev/net/tun \
        -v /home/bittorrent/data/:/data \
        -e "OPENVPN_PROVIDER=TORGUARD" \
        -e "OPENVPN_USERNAME=bittorrent@example.com" \
        -e "OPENVPN_PASSWORD=hunter2" \
        -e "OPENVPN_CONFIG=CA\ Toronto" \
        -e "OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60" \
        -e "TRANSMISSION_UMASK=0" \
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