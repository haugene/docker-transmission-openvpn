# OpenVPN (Edge) and Transmission with WebUI

[![Docker Pulls](https://img.shields.io/docker/pulls/fluxstate/transmission-vpn-edge.svg)](https://hub.docker.com/r/fluxstate/transmission-vpn-edge/)

This container contains OpenVPN and Transmission 3.00Z+ with a configuration
where Transmission is running only when OpenVPN has an active tunnel.
It has built in support for many popular VPN providers to make the setup easier.

## Read this first

The documentation for this image is hosted on GitHub pages:

https://haugene.github.io/docker-transmission-openvpn/

If you can't find what you're looking for there, please have a look
in the [discussions](https://github.com/haugene/docker-transmission-openvpn/discussions)
as we're trying to use that for general questions.

If you have found what you believe to be an issue or bug, create an issue and provide
enough details for us to have a chance to reproduce it or undertand what's going on.
**NB:** Be sure to search for similar issues (open and closed) before opening a new one.

## Quick Start

These examples shows valid setups using PIA as provider for both
docker run and docker-compose. Note that you should read some documentation
at some point, but this is a good place to start.

### Docker run

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
              fluxstate/transmission-vpn-edge
```

### Docker Compose
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
        image: fluxstate/transmission-vpn-edge
```
