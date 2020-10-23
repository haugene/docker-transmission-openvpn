# OpenVPN and Transmission with WebUI

[![CircleCI builds](https://img.shields.io/circleci/build/github/haugene/docker-transmission-openvpn)](https://circleci.com/gh/haugene/docker-transmission-openvpn)
[![Docker Pulls](https://img.shields.io/docker/pulls/haugene/transmission-openvpn.svg)](https://hub.docker.com/r/haugene/transmission-openvpn/)
[![Join the chat at https://gitter.im/docker-transmission-openvpn/Lobby](https://badges.gitter.im/docker-transmission-openvpn/Lobby.svg)](https://gitter.im/docker-transmission-openvpn/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Deprecation Warning - changes are coming!

**TL;DR:** Nothing has changed yet for the `latest` tag, but there is a 3.0 version coming. Until then the `dev` tag could be more unstable than before.

After years of maintaining and developing this project there are a couple of things that users keep asking about and that
we now want to change in order to eventually make it easier for everyone.
It looks like we will be close to 100% backwards compatible but we will probably have a couple of breaking changes where users would have to rename a config parameter or two, etc.

As of now we are devoting the dev branch to development of the new version 3.0, and the master branch will continue on 2.x.
Updates to openvpn configs and other smaller changes should be contributed to the master branch as the dev branch will not be merged into master before we have developed, tested and stabilized the new version.

Some highlights on version 3.x:
* We're dropping the ubuntu based image and making alpine the default (reduce double maintenance)
* We're making Transmission settings persistent by default, removing the need for all the environment variables (but keeping support for it)
* We're making it easier to provide your own OpenVPN (.ovpn) config file.
* Possibly extracting the OpenVPN configs so that we can maintain that in a separate project and focus on the core in this project.

These changes will not be in effect in a while yet, and I will update here when they are and provide a list of non backwards compatible changes.
If you are following the "latest" tag, at some point it will be changed to the 3.x version and your container might break. At that point, either follow the
upgrade guide (coming) or revert the version to the latest release on 2.x versions.

The dev branch will be used for the 3.x going forwards, so to all of you following that one. You have been warned, it might be a bit unstable going forwards.

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
