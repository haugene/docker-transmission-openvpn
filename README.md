# OpenVPN and Transmission with WebUI

[![Docker Build](https://img.shields.io/github/actions/workflow/status/haugene/docker-transmission-openvpn/docker-image-builds.yml
)](https://hub.docker.com/r/haugene/transmission-openvpn/)
[![Docker Pulls](https://img.shields.io/docker/pulls/haugene/transmission-openvpn.svg)](https://hub.docker.com/r/haugene/transmission-openvpn/)

This container contains OpenVPN and Transmission with a configuration
where Transmission is running only when OpenVPN has an active tunnel.
It has built-in support for many popular VPN providers to make the setup easier.

## Read this first

The documentation for this image is hosted on GitHub pages:

https://haugene.github.io/docker-transmission-openvpn/

If you can't find what you're looking for there, please have a look
in the [discussions](https://github.com/haugene/docker-transmission-openvpn/discussions)
as we're trying to use that for general questions.

If you have found what you believe to be an issue or bug, create an issue and provide
enough details for us to have a chance to reproduce it or understand what's going on.
**NB:** Be sure to search for similar issues (open and closed) before opening a new one.

## Quick Start

These examples show valid setups using PIA as the provider for both
docker run and docker-compose. Note that you should read some documentation
at some point, but this is a good place to start.

### Docker run

```
$ docker run --cap-add=NET_ADMIN -d \
              -v /your/storage/path/:/data \
              -v /your/config/path/:/config \
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

### Docker Compose
```
version: '3.3'
services:
    transmission-openvpn:
        cap_add:
            - NET_ADMIN
        volumes:
            - '/your/storage/path/:/data'
            - '/your/config/path/:/config'
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

## Known issues

If you've been running a stable setup that has recently started to fail, please check your logs.
Are you seeing `curl: (6) getaddrinfo() thread failed to start` or `WARNING: initial DNS resolution test failed`?
Then have a look at [#2410](https://github.com/haugene/docker-transmission-openvpn/issues/2410)
and [this comment](https://github.com/haugene/docker-transmission-openvpn/issues/2410#issuecomment-1319299598)
in particular. There is a fix and a workaround available.

## Image versioning

We aim to create periodic fixed releases with a [semver](https://semver.org/) versioning scheme.
The latest of the tagged fixed releases will also have the `latest` tag.

A semver release will be tagged with `major`, `major.minor` and `major.minor.patch` versions so that you can lock
the version at either level.

We also have a tag called `edge` which will always be the latest commit on `master`, and `dev` which is the last commit on the `dev` branch.
From time to time we can also have various `beta` branches and tags, but using either dev or beta tags is probably not for the average user
and you should expect there to be occasional breakage or even the deletion of the tags upstream.

## Please help out (about:maintenance)
This image was created for my own use, but sharing is caring, so it had to be open source.
It has now gotten quite popular, and that's great! But keeping it up to date, providing support, fixes
and new features take time. If you feel that you're getting a good tool and want to support it, there are a couple of options:

A small montly amount through [![Donate with Patreon](images/patreon.png)](https://www.patreon.com/haugene) or
a one time donation with [![Donate with PayPal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=73XHRSK65KQYC)

All donations are greatly appreciated! Another great way to contribute is of course through code.
A big thanks to everyone who has contributed so far!
