# Running the container

Many platforms ship with a Docker runtime and have their own way of setting this up.
I'm then thinking about NAS servers specifically, but also Unraid and others. In addition to this we have
the container management solutions like [Portainer](https://www.portainer.io/)

This page will only discuss the tooling that a Docker installation comes with. That means `docker run ..`
and `docker-compose`. In the end that is what the other managers do as well and it's the common ground here.
I'm very happy to set up a platform specific installation page and link to it from here.
Open an issue or PR if you want to contribute with documentation for your favourite platform.


The images available on the Docker Hub are multiarch manifests. This means that they point to multiple images
that are built for different CPU architectures like ARM for Raspberry Pi. You can `haugene/transmission-openvpn`
on any of these architectures and Docker will get the correct one.

## Starting the container

The example Docker run command looks like this:

```
$ docker run --cap-add=NET_ADMIN -d \
              -v /your/storage/path/:/data \
              -e OPENVPN_PROVIDER=PIA \
              -e OPENVPN_CONFIG=france \
              -e OPENVPN_USERNAME=user \
              -e OPENVPN_PASSWORD=pass \
              -e LOCAL_NETWORK=192.168.0.0/16 \
              --log-driver json-file \
              --log-opt max-size=10m \
              -p 9091:9091 \
              haugene/transmission-openvpn
```

The example docker-compose.yml looks like this:

```
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
        image: haugene/transmission-openvpn
```

These configs are equivalent. Running `docker-compose up` with that compose file will result in
the same options being sent to the Docker engine as the run statement before it.

## Three things to remember

#### 1. The container assumes that you mount a folder to /data

Technically you don't have to do this, but it is by far the most manageable way of getting
the downloaded files onto your host system **and** Transmission will store it's state there.
So if you don't mount this directory then you will loose all your torrents on image updates.

#### 2. It is not mandatory, but setting OPENVPN_CONFIG is good

If you don't set this then there should be a default config for each provider that is chosen, and that should work fine.
The benefit of choosing yourself is that you can choose a region that is closer to you and that might be better for speed.
I also believe that tinkering with this builds some familiarity with the image and some confidence and understanding for future debugging.

We're now moving towards a setup where we download the configs for our providers when the container starts.
That is great from a maintenance perspective, but it also means that we don't know the valid choices for the providers ahead of time.
A tip for finding out is to set `OPENVPN_CONFIG=dummy` and start it. This will fail, but in the logs it will print all the valid options.

Pro tip: choose multiple servers. For example: `OPENVPN_CONFIG=france,sweden,austria,italy,belgium`
This will ensure a location near you, but at the same time it will allow some redundancy. Set Docker to restart the container
automatically and you have a failover mechanism. The container chooses one of the configs at random when it starts and it will bounce
from server to server until it finds one that works.

#### 3. You might not be able to access the Web UI on the first try

The `LOCAL_NETWORK=192.168.0.0/16` tries to fix this for you, but it might not work if your local LAN DHCP server hands out addresses outside that range.

If your local network is in the `10.x.y.z` space for example then you need to set `LOCAL_NETWORK=10.x.0.0/16` or `LOCAL_NETWORK=10.x.y.0/24`.
These are called CIDR addresses and you can read up on them. The short story is that /24 will allow for any value in the last digit place
while /16 will allow any value in the two last places. Be sure to only allow IPs that are in the [private IP ranges](https://en.wikipedia.org/wiki/Private_network).
This option punches a hole in the VPN for the IPs that you specify. It is neccessary to reach your Web UI but narrower ranges are better than wide ones.

With that said. If you know that you're on a "typical" network with your router at 192.168.1.1, then `LOCAL_NETWORK=192.168.1.0/24` is better than `LOCAL_NETWORK=192.168.0.0/16`. That way you only allow access form 192.168.1.x instead of 192.168.x.y.

There is an alternative to the LOCAL_NETWORK environment variable, and that is a reverse proxy in the same docker network as the vpn container.
Because this topic is both quite complex and very important there is a separate page on [VPN and Networking](vpn-networking.md) in the container and it goes into depth on why this is.