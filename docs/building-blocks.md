# The basic building blocks

## The goal

The core functionality of this image is to let the user run a
VPN tunnel and Transmission as easy as possible. Transmission
should only run while the VPN is active and any disconnect
from VPN should cause Transmission to stop.

The container should provide community best practices on how to configure the kill switch, firewall and tweaks on the
OpenVPN configs to make it run as fast and secure as possible.

## It goes like this

To understand how it works, this is the most important events
and who/what starts them.

1. You start the container
2. The container starts OpenVPN
3. OpenVPN starts/stops Transmission

When you start the container it is instructed to run a script
to start OpenVPN. This is defined in [the Dockerfile](https://github.com/haugene/docker-transmission-openvpn/blob/master/Dockerfile).
This script is responsible for doing initial setup and prepare what is needed for OpenVPN to run successfully.

## Starting OpenVPN

The main purpose of the startup script is to figure out which OpenVPN config to use.
OpenVPN itself can be started with a single argument, and that is the config file.
We also add a few more to tell it to start Transmission when the VPN tunnel is
started and to stop Transmission when OpenVPN is stopped. That's it.

Apart from that the script does some firewall config, vpn interface setup and possibly other
things based on your settings. There are also some reserved script names that a user can mount/add to
the container to include their own scripts as a part of the setup or teardown of the container.

Anyways! You have probably seen the docker run and docker-compose configuration examples
and you've put two and two together: This is where environment variables comes in.
Setting environment variables is a common way to pass configuration options to containers
and it is the way we have chosen to do it here.
So far we've explained the need for `OPENVPN_PROVIDER` and `OPENVPN_CONFIG`. We use the
combination of these two to find the right config. `OPENVPN_CONFIG` is not set as a mandatory
option as each provider should have a default config that will be used if none is set.

With the config file identified we're ready to start OpenVPN, the only thing missing are probably
a username and password. There are some free providers out there, but they are the exceptions to the rule.
We have to inject the username/password into the config somehow. Again there are exceptions but the majority
of configs from regular providers contain a line with `auth-user-pass` which will make OpenVPN prompt for username
and password when you start a connection. That will obviously not work for us so we need to modify that option.
If it's followed by a path to a file, it will read the first line of that file as username and the second line as password.

You provide your username and password as `OPENVPN_USERNAME` and `OPENVPN_PASSWORD`. These will be
written into two lines in a file called `/config/openvpn-credentials.txt` on startup by the start script.
Having written your username/password to a file, we can successfully start OpenVPN.

## Starting Transmission

We're using the `up` option from OpenVPN to start Transmission.
> --up cmd<br>
> &nbsp;&nbsp;&nbsp;&nbsp;Run command cmd after successful TUN/TAP device open

This means that Transmission will be started when OpenVPN has connected successfully and opened the tunnel device.
We are having OpenVPN call the [tunnelUp.sh](https://github.com/haugene/docker-transmission-openvpn/blob/master/openvpn/tunnelUp.sh)
script which in turn will call the start scripts for
[Transmission](https://github.com/haugene/docker-transmission-openvpn/blob/master/transmission/start.sh) and 
[Privoxy](https://github.com/haugene/docker-transmission-openvpn/blob/master/privoxy/start.sh).

The up script will be called with a number of parameters from OpenVPN, and among them is the IP of the tunnel interface.
This IP is the one we've been assigned by DHCP from the OpenVPN server we're connecting to.
We use this value to override Transmissions bind address, so we'll only listen for traffic from peers on the VPN interface.

The startup script checks to see if one of the [alternative web ui's](config-options.md#alternative_web_uis) should be used for Transmission.
It also sets up the user that Transmission should be run as, based on the PUID and PGID passed by the user
along with selecting preferred logging output and a few other tweaks.

Before starting Transmission we also need to see if there are any settings that should be overridden.
One example of this is binding Transmission to the IP we've gotten from our VPN provider.
Here we check if we find any environment variables that match a setting that we also see in settings.json.
This is described in the [config section](config-options/#transmission_configuration_options).
Setting a matching environment variable will then override the setting in Transmission.

OpenVPN does not pass the environment variables it was started with to Transmission.
To still be able to access them when starting Transmission, we're writing the ones we need to a file when starting OpenVPN.
That way we can read them back and use them here. With the environment variables in place
[this script](https://github.com/haugene/docker-transmission-openvpn/blob/master/transmission/updateSettings.py) then overwrites
the selected properties in settings.json and we're ready to start Transmission itself.

After starting Transmission there is an optional step that some providers have;
to get an open port and set it in Transmission. **Opening a port in your local router does not work**.
I made that bold because it's a recurring theme. It's not intuitive until it is I guess.
Since all your traffic is going through the VPN, which is kind of the point, the port you have to open is not on your router.
Your router's external IP address is the destination of those packets. It is on your VPN providers end that it has to be opened.
Some providers support this, other don't. We try to write scripts for those that do and that script will be executed
after starting Transmission if it exists for your provider.

At this point Transmission is running and everything is great!
But you might not be able to access it, and that's the topic of the [networking section](vpn-networking.md).