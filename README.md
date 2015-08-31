# Transmission with WebUI and OpenVPN
Docker container which runs Transmission torrent client with WebUI while connecting to OpenVPN. 
It bundles certificates and configurations for the following VPN providers:
* Private Internet Access
* BTGuard
* TigerVPN
* FrootVPN

When using PIA as provider it will update Transmission hourly with assigned open port. Please read the instructions below.

## Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it. To run the container use this command:

```
$ docker run --privileged  -d \
              -v /your/storage/path/:/data \
              -e "OPENVPN_PROVIDER=PIA" \
              -e "OPENVPN_CONFIG=Netherlands" \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 9091:9091 \
              haugene/transmission-openvpn
```

You must set the environment variables `OPENVPN_PROVIDER`, `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` to provide basic connection details.

The `OPENVPN_CONFIG` is an optional variable. If no config is given, a default config will be selected for the provider you have chosen.
Find available OpenVPN configurations by looking in the openvpn folder of the GitHub repository.

As you can see, the container also expects a data volume to be mounted. 
This is where Transmission will store your downloads, incomplete downloads and look for a watch directory for new .torrent files.
By default there will also be created a transmission-home folder under /data where Transmission state is stored.


### Required environment options
| Variable | Function | Example |
|----------|----------|-------|
|`OPENVPN_PROVIDER` | Sets the OpenVPN provider to use. | `OPENVPN_PROVIDER=BTGUARD` or <br>`OPENVPN_PROVIDER=PIA` or <br>`OPENVPN_PROVIDER=TIGER` or <br>`OPENVPN_PROVIDER=FROOT`|
|`OPENVPN_USERNAME`|Your OpenVPN username |`OPENVPN_USERNAME=asdf`|
|`OPENVPN_PASSWORD`|Your OpenVPN password |`OPENVPN_PASSWORD=asdf`|

### Network configuration options
| Variable | Function | Example |
|----------|----------|-------|
|`OPENVPN_CONFIG` | Sets the OpenVPN endpoint to connect to. | `OPENVPN_CONFIG=UK Southampton`|
|`RESOLV_OVERRIDE` | The value of this variable will be written to `/etc/resolv.conf`. | `RESOLV_OVERRIDE=nameserver 8.8.8.8\nnameserver 8.8.4.4\n`|

### Transmission configuration options

You may override transmission options by setting the appropriate environment variable.

The environment variables are the same name as used in the transmission settings.json file and follow the format given in these examples:

| Transmission variable name | Environment variable name |
|----------------------------|---------------------------|
| `speed-limit-up` | `TRANSMISSION_SPEED_LIMIT_UP` |
| `speed-limit-up-enabled` | `TRANSMISSION_SPEED_LIMIT_UP_ENABLED` |
| `ratio-limit` | `TRANSMISSION_RATIO_LIMIT` |
| `ratio-limit-enabled` | `TRANSMISSION_RATIO_LIMIT_ENABLED` |

As you can see the variables are prefixed with `TRANSMISSION_`, the variable is capitalized, and `-` is converted to `_`.

PS: `TRANSMISSION_BIND_ADDRESS_IPV4` will be overridden to the IP assigned to your OpenVPN tunnel interface. This is to prevent leaking of the host IP.

## Access the WebUI
But what's going on? My http://my-host:9091 isn't responding?
This is because the VPN is active, and since docker is running in a different ip range than your client the response to your request will be treated as "non-local" traffic and therefore be routed out through the VPN interface.

### How to fix this
There are several ways to fix this. You can pipe and do fancy iptables or ip route configurations on the host and in the Docker image. But I found that the simplest solution is just to proxy my traffic. Start a Nginx container like this:

```
$ docker run -d \
      -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
      -p 8080:8080 \
      nginx
```

Where /path/to/nginx.conf has this content:

```
events {
  worker_connections 1024;
}

http {
  server {
    listen 8080;
    location / {
      proxy_pass http://host.ip.address.here:9091;
    }
  }
}
```
Your Transmission WebUI should now be avaliable at "your.host.ip.addr:8080/transmission/web/".
Change the port in the docker run command if 8080 is not suitable for you.

### Known issues
Some have encountered problems with DNS resolving inside the docker container. This causes trouble because OpenVPN will not be able to resolve the host to connect to. If you have this problem, please refer to issue #4 on GitHib and you might want to use the `RESOLV_OVERRIDE` flag described in "Network configuration options"

If you are having issues with this container please submit an issue on GitHub. Please provide logs, docker version and other information that can simplify reproducing the issue. Using the latest stable verison of Docker is always recommended. Support for older version is on a best-effort basis.

## Building the container yourself
To build this container, clone the repository and cd into it.

### Build it:
```
$ cd /repo/location/docker-transmission-openvpn
$ docker build -t docker-transmission-openvpn .
```
### Run it:
```
$ docker run --privileged  -d \
              -v /your/storage/path/:/data \
              -e "OPENVPN_PROVIDER=PIA" \
              -e "OPENVPN_CONFIG=Netherlands" \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 9091:9091 \
              docker-transmission-openvpn
```

This will start a container as described in the "Run container from Docker registry" section. 

## What if I want to run the container interactively.
If you want do have access inside the container while running you have two choices. To have a look inside an already running container, use docker exec to get a terminal inside the container.

```
$ docker ps | grep transmission-openvpn | awk '{print $1}' // Prints container id
$ af4dd385916d
$ docker exec -it af4dd bash
```

If you want to start the container without it starting OpenVPN on boot, then run the image without daemonizing and use bash as entrypoint.

```
$ docker run --privileged -it transmission-openvpn bash
```

From there you can start the service yourself, or do whatever (probably developer-related) you came to do.

## Controlling Transmission remotely
The container exposes /config as a volume. This is the directory where the supplied transmission and OpenVPN credentials will be stored.
If you have transmission authentication enabled and want scripts in another container to access and control the transmission-daemon, this can be a handy way to access the credentials.
For example, another container may pause or restrict transmission speeds while the server is streaming video.
