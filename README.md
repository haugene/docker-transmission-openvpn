# OpenVPN and Transmission with WebUI

[![CircleCI builds](https://img.shields.io/circleci/build/github/haugene/docker-transmission-openvpn)](https://circleci.com/gh/haugene/docker-transmission-openvpn)
[![Docker Pulls](https://img.shields.io/docker/pulls/haugene/transmission-openvpn.svg)](https://hub.docker.com/r/haugene/transmission-openvpn/)
[![Join the chat at https://gitter.im/docker-transmission-openvpn/Lobby](https://badges.gitter.im/docker-transmission-openvpn/Lobby.svg)](https://gitter.im/docker-transmission-openvpn/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Version 3.0 released - we have some breaking changes (but not much)

Those of you who are following this project knows that we have had some larger changes coming for a while.
Hobby projects often get last in line for some love and care, and it took longer than I hoped but here we are.

Some highlights on version 3.0:
* We're dropping the ubuntu based image and making alpine the default (reduce double maintenance)
* We're making Transmission settings persistent by default, removing the need for all the environment variables (but keeping support for it)
* We're making it easier to provide your own OpenVPN (.ovpn) config file - adding scripts in the container to modify provider configs as needed to fit the container setup. (still in early stages at this point)
* We're adding a standardized way to add scripts for doing necessary setup of a provider. This usually means to download a .ovpn config bundle, unpack it and modify it correctly to work in this container.

Hopefully these changes will improve the usability of this container. As maintainers we also hope that it will free up time to keep the container up to date and stable instead of managing thousands of .ovpn files coming and going.

I'll try to keep a list of breaking changes here, and add to it if we come across more:
* The CREATE_TUN_DEVICE variable now defaults to true. Mounting /dev/net/tun will lead to an error message in the logs unless you explicitly set it to false.
* The DOCKER_LOG variable is renamed to LOG_TO_STDOUT
* If Transmission is running but you can't connect to torrents, try deleting (or rename to .backup) the settings.json file and restart.

PS: Now more than ever. We appreciate that you report bugs and issues when you find them. But as there might be more than ususal, please make sure you search and look for a similar one before possibly creating a duplicate.
And you can always revert back to the latest tag on the 2.x versions which is 2.14. Instead of running with `haugene/transmission-openvpn` simply use `haugene/transmission-openvpn:2.14` instead. We hope that won't be necessary though :)

## Quick Start

This container contains OpenVPN and Transmission with a configuration
where Transmission is running only when OpenVPN has an active tunnel.
It bundles configuration files for many popular VPN providers to make the setup easier.

```
$ docker run --cap-add=NET_ADMIN -d \
              -v /your/storage/path/:/data \
              -e OPENVPN_PROVIDER=PIA \
              -e OPENVPN_CONFIG=France \
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
        environment:
            - OPENVPN_PROVIDER=PIA
            - OPENVPN_CONFIG=France
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
and new features takes time. If you feel that you're getting a good tool and want to support it, there are a couple of options:

A small montly amount through [![Donate with Patreon](images/patreon.png)](https://www.patreon.com/haugene) or
a one time donation with [![Donate with PayPal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=73XHRSK65KQYC)

All donations are greatly appreciated! Another great way to contribute is of course through code.
A big thanks to everyone who has contributed so far!
