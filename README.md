# OpenVPN and Transmission with WebUI

[![CircleCI builds](https://img.shields.io/circleci/build/github/haugene/docker-transmission-openvpn)](https://circleci.com/gh/haugene/docker-transmission-openvpn)
[![Docker Pulls](https://img.shields.io/docker/pulls/haugene/transmission-openvpn.svg)](https://hub.docker.com/r/haugene/transmission-openvpn/)
[![Join the chat at https://gitter.im/docker-transmission-openvpn/Lobby](https://badges.gitter.im/docker-transmission-openvpn/Lobby.svg)](https://gitter.im/docker-transmission-openvpn/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Quick Start

This container contains OpenVPN and Transmission with a configuration
where Transmission is running only when OpenVPN has an active tunnel.
It bundles configuration files for many popular VPN providers to make the setup easier.

```
$ docker run --cap-add=NET_ADMIN -d \
              -v /your/storage/path/:/data \
              -v /etc/localtime:/etc/localtime:ro \
              -e CREATE_TUN_DEVICE=true \
              -e OPENVPN_PROVIDER=PIA \
              -e OPENVPN_CONFIG=CA\ Toronto \
              -e OPENVPN_USERNAME=user \
              -e OPENVPN_PASSWORD=pass \
              -e WEBPROXY_ENABLED=false \
              -e LOCAL_NETWORK=192.168.0.0/16 \
              --log-driver json-file \
              --log-opt max-size=10m \
              -p 9091:9091 \
              haugene/transmission-openvpn
```

## Docker Compose
```
version: '3.3'
services:
    transmission-openvpn:
        volumes:
            - '/your/storage/path/:/data'
            - '/etc/localtime:/etc/localtime:ro'
        environment:
            - CREATE_TUN_DEVICE=true
            - OPENVPN_PROVIDER=PIA
            - OPENVPN_CONFIG=CA Toronto
            - OPENVPN_USERNAME=user
            - OPENVPN_PASSWORD=pass
            - WEBPROXY_ENABLED=false
            - LOCAL_NETWORK=192.168.0.0/16
        cap_add:
            - NET_ADMIN
        logging:
            driver: json-file
            options:
                max-size: 10m
        ports:
            - '9091:9091'
        image: haugene/transmission-openvpn
```

## Documentation
The full documentation is available at https://haugene.github.io/docker-transmission-openvpn/.

## Please help out (about:maintenance)
This image was created for my own use, but sharing is caring, so it had to be open source.
It has now gotten quite popular, and that's great! But keeping it up to date, providing support, fixes
and new features takes a lot of time.

I'm therefore kindly asking you to donate if you feel like you're getting a good tool
and you're able to spare some dollars to keep it functioning as it should. There's a couple of ways to do it:

Become a patron, supporting the project with a small monthly amount.

[![Donate with Patreon](images/patreon.png)](https://www.patreon.com/haugene)

Make a one time donation through PayPal.

[![Donate with PayPal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=73XHRSK65KQYC)

Or use this referral code to DigitalOcean and get 25$ in credits, if you're interested in a cloud setup.

[![Credits on DigitalOcean](images/digitalocean.png)](https://m.do.co/c/ca994f1552bc)

You can also help out by submitting pull-requests or helping others with
open issues or in the gitter chat. A big thanks to everyone who has contributed so far!
And if you could be interested in joining as collaborator, let me know.
