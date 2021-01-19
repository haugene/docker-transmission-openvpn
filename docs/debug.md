# Debugging your setup

The goal of this page is to provide a common set of tests that can be run to try to narrow down
an issue with the container before you actually create a new issue for it. We see a lot of repeat
business in the issues section and spending time answering questions for individual setups takes
away from improving the container and making it more stable in the first place.

This guide should be improved over time but can hopefully help you point out the most common errors
and provide some pointers on how to proceed. A short summary of what you've tried should be added to
the description if you can't figure out what's wrong with your setup and create an issue for it.

## Introduction and assumptions

I am going to assume that you have shell access to the host and that you can use `docker run`
commands to test it. If you're a docker-compose user then you can make a similar setup in docker-compose.
If you are using any of the NAS container orchestration UIs then you just have to mimic this behaviour
as best you can. Note that you can ssh into the NAS and run commands directly.

NOTE: The commands listed here uses the --rm flag which will remove the container from the host when it
shuts down. And as we're not mounting any volumes here, your host system will not be altered from running
any of these commands. If any command breaks with this principle it will be noted.

## Checking that Docker works properly

In order for this container to work you have to have a working Docker installation on your host.

We'll begin very simple with this command that will print a welcome message if Docker is properly installed.
```
docker run --rm hello-world
```

Then we can try to run an alpine image, install curl and run curl to get your public IP.
This verifies that Docker containers on your host has a working internet access
and that they can look up hostnames with DNS.
```
docker run --rm -it alpine sh -c "apk add curl && curl ipecho.net/plain"
```

If you get an error with "Could not resolve host" then you have to look at the dns options in
[the Docker run reference](https://docs.docker.com/engine/reference/run/#network-settings).

Finally we will check that your Docker daemon runs with a bridge network as the default network driver.
The following command runs an alpine container and prints it's iptable routes. It probably outputs two
lines and one of them starts with `172.x.0.0/16 dev eth0` and the other one also references `172.x.0.1`.
The 172 addresses are a sign that you're on a Docker bridge network. If your local IP like `192.168.x.y`
shows up your container is running with host networking and the VPN container would affect the entire host
instead of just affecting Transmission running within the container.
```
docker run --rm -it alpine ip r
```

If you have gotten any errors so far you have to refer to Docker documentation and other forums to get
help getting Docker to work.

## Try running the container with an invalid setup

We'll keep this brief because it's not the most useful step, but you can actually verify a bit anyways.

Run this command (even if PIA is not your provider) and do not insert your real username/password:
```
docker run --rm -it -e OPENVPN_PROVIDER=PIA -e OPENVPN_CONFIG=france -e OPENVPN_USERNAME=donald -e OPENVPN_PASSWORD=duck haugene/transmission-openvpn
```

At this point the commands are getting longer. I'll start breaking them up into lines using \ to escape the line
breaks. For those that are new to shell commands; a \ at the end of the line will tell the shell to keep on
reading as if it was on the same line. You can copy-paste this somewhere and put everythin on the same line
and remove the \ characters if you want to. The same command then becomes:
```
docker run --rm -it \
  -e OPENVPN_PROVIDER=PIA \
  -e OPENVPN_CONFIG=france \
  -e OPENVPN_USERNAME=donald \
  -e OPENVPN_PASSWORD=duck \
  haugene/transmission-openvpn
```

This command should fail and exit with three lines that look like this (I've trimmed it a bit):
```
Peer Connection Initiated with ...
AUTH: Received control message: AUTH_FAILED
SIGTERM[soft,auth-failure] received, process exiting
```

And this is not nothing. The container has made contact with the VPN server and they have agreed
that you do not have provided correct authentication. So we're getting somewhere.

## Running with a valid configuration

Upgrading slightly from the last command we need to add our real provider, config and username/password.
This is what the container needs to be able to connect to VPN. The config is not a mandatory option and
all providers should have a default that is used if you don't set it. But I will set it here anyways as
I think it's good to know where and what you're connecting to.

The command is basically the same. I'm going to stick with PIA/france as I am a PIA user, but you should set
one of the [supported providers](supported-providers.md) or provide your own config using the 
[custom configuration option](supported-providers.md#using_a_custom_provider). Since I'm now expecting to connect
successfully to my VPN provider I have to give the container elevated access to modify networking needed to
establish a VPN tunnel. I'll add the `--cap-add=NET_ADMIN` and you can read more about
that [here](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities).

Also because I'm using PIA and they support port forwarding which is automatically configured in this 
container I will disable that script for now. It's unnecessary at this point and I don't want to introduce
more error sources than I have to.

```
docker run --rm -it --cap-add=NET_ADMIN \
  -e OPENVPN_PROVIDER=PIA \
  -e OPENVPN_CONFIG=france \
  -e OPENVPN_USERNAME=username \
  -e OPENVPN_PASSWORD=password \
  -e DISABLE_PORT_UPDATER=true \
  haugene/transmission-openvpn
```

The logs should be longer this time, and you should end up with `Initialization Sequence Completed` at the end.
If you don't see this message then look through your logs for errors and see if you can find your error in the
list in the [FAQ](faq.md). If the error is not easily understandable or listed in the FAQ, open a new issue on it.

## Checking if Transmission is running

We're continuing with the `docker run` command from the last example. Because we have not yet introduced the
LOCAL_NETWORK variable you cannot access Transmission that is running in the container. We have not exposed
any ports on your host either so Transmission is not reachable from outside of the container as of now.

You don't need to expose Transmission outside of the container to contact it though. You can get another shell
inside the same container that you are running and try to curl Transmission web ui from there.

If this gets too complicated then you can skip to the next point, but please try to come back here
if the next point fails. One thing is not being able to access Transmission which might be network related,
but if Transmission is not running it's something else entirely.

If you run `docker ps` you should get a list of all running docker containers. If the list is too long then
you can ask for only transmission-openvpn containers with `docker ps --filter ancestor=haugene/transmission-openvpn`.

Using the Container ID from that list you can run `docker exec -it <container-id> bash`.
Once you're in the container run `curl localhost:9091` and you should expect to get
`<h1>301: Moved Permanently</h1>` in return. This is because Transmission runs at /web/transmission and
tries to redirect you there. It doesn't matter because you now see that Transmission is running and
apparently doing well.

## Accessing Transmission Web UI

If you've come this far we hopefully will be able to connect to the Transmission Web UI from your browser.
In order to do this we have to know what LAN IP your system is on. The reason for this is a bit complex and
is described in the [VPN networking](vpn-networking.md) section. The short version is that OpenVPN need to
be able to differentiate between what traffic to tunnel and what to let go. Since the VPN is running on
the Docker bridge network it is not able to detect computers on your LAN as actually being local devices.

We'll base ourselves on the command from the previous sections, but to access Transmission we need to
expose the 9091 port to the host and tell the containers what IP ranges NOT to tunnel. Whatever you put
in LOCAL_NETWORK will be trusted as a local network and traffic to those IPs will not be tunneled.
Here we will assume that you're on one of the common 192.168.x.y subnets.

The command then becomes:
```
docker run --rm -it --cap-add=NET_ADMIN \
  -p 9091:9091 \
  -e LOCAL_NETWORK=192.168.0.0/16 \
  -e OPENVPN_PROVIDER=PIA \
  -e OPENVPN_CONFIG=france \
  -e OPENVPN_USERNAME=username \
  -e OPENVPN_PASSWORD=password \
  -e DISABLE_PORT_UPDATER=true \
  haugene/transmission-openvpn
```

With any luck you should now be able to access Transmission at [http://localhost:9091](http://localhost:9091)
or whatever server IP where you have started the container.

NOTE: If you're trying to run this beside another container you can use `-p 9092:9091` to bind 9092
on the host instead of 9091 and avoid port conflict.

## Now what?

If this guide has failed at some point then you should create an issue for it. Please add the command
that you ran and the logs that was produced.

If you're now able to access Transmission and it seems to work correctly then you should add a volume mount
to the `/data` folder in the container. You'll then have a setup like what's shown on the
[main GitHub page](https://github.com/haugene/docker-transmission-openvpn/) of this project.

If you have another setup that does not work then you now have two versions to compare and maybe
that will lead you to find the error in your old setup. If the setup is the same but this version works then
the error is in your state. Transmission stores its state in /data/transmission-home by default and
it might have gotten corrupt. One simple thing to try is to delete the settings.json file that is found here.
We do mess with that file and we might have corrupted it. Apart from that we do not change anything within
the Transmission folder and any issues should be asked in Transmission forums.

## Conclusion

I hope this has helped you to solve your problem or at least narrow down where it's coming from.
If you have suggestions for improvements do not hesitate to create an issue or even better open
a PR with your proposed changes.