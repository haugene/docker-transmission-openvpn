<h1 align="center">
  OpenVPN and Transmission with WebUI
</h1>

<p align="center">
  Docker container running Transmission torrent client with WebUI over an OpenVPN tunnel
  <br/><br/>

  <a href="https://hub.docker.com/r/haugene/transmission-openvpn/">
    <img alt="build" src="https://img.shields.io/docker/automated/haugene/transmission-openvpn.svg" />
  </a>
  <a href="https://hub.docker.com/r/haugene/transmission-openvpn/">
    <img alt="pulls" src="https://img.shields.io/docker/pulls/haugene/transmission-openvpn.svg" />
  </a>
  <a href="https://gitter.im/docker-transmission-openvpn/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge">
    <img alt="Join the chat at https://gitter.im/docker-transmission-openvpn/Lobby" src="https://badges.gitter.im/docker-transmission-openvpn/Lobby.svg" />
  </a>
  <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=73XHRSK65KQYC">
    <img alt="Donate with PayPal" src="https://img.shields.io/badge/Donate-PayPal-green.svg">
  </a>
  <a href="https://www.patreon.com/haugene">
    <img alt="Donate with Patreon" src="https://github.com/haugene/docker-transmission-openvpn/raw/master/images/patreon.png">
  </a>
</p>

## Overview

You have found the documentation. That usually means that you either:

1. Want to read a bit about how the image is built and how it works
2. Want to get started, and are looking for a setup guide
3. Already have a setup, but something is broken

We'll try to address them here but no matter which one of them it is, knowing
more about this image makes it easier to understand how it should be and what
could be wrong. So starting with number 1 is never a bad idea.

**NB:** These pages are under re-construction. Follow the issue [here](https://github.com/haugene/docker-transmission-openvpn/issues/1558) and feel free to comment or help out :) Also we just released version 3.0, so if you have some breakage - [please read here](v3.md).

## Good places to start

* [The basic building blocks](building-blocks.md)
* [Running the container](run-container.md)
* [VPN and networking in containers](vpn-networking.md)
* [Supported providers and server locations](supported-providers.md)
* [Provider specific features/instructions](provider-specific.md)
* [Configuration options list](config-options.md)

## Troubleshooting

* [Frequently asked questions](faq.md)
* Debugging your setup (coming)
* [Tips & Tricks](tips-tricks.md)

## Additional features

* [Web proxy: Tinyproxy](web-proxy.md)
* [RSS Plugin support](rss-plugin.md)