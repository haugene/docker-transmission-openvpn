Private Internet Access OpenVPN - Transmission
===
This Docker container lets you run Transmission with WebUI while connecting to PIA VPN. It updates Transmission hourly with assigned open port from PIA. Please read the instructions below.

## Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it. To run the container use this command:

```
$ docker run --privileged  -d \
              -v /your/storage/path/:/data \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 9091:9091 \
              haugene/transmission-openvpn
```

or you could optionally specify which vpn server to use by setting an environment variable to one of the ovpn configs avaliable [in this folder](https://github.com/haugene/docker-transmission-openvpn/tree/master/piaconfig).

```
$ docker run --privileged  -d \
              -v /your/storage/path/:/data \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 9091:9091 \
              -e "OPEN_VPN_CONFIG=US West" \
              haugene/transmission-openvpn
```

As you can see, the container expects a data volume to be mounted. It is used for storing your downloads from Transmission. The container comes with a default Transmission `settings.json` file that expects the folders `completed`, `incomplete`, and `watch` to be present in /your/storage/path (aka /data). This is where Transmission will store your downloads, incomplete downloads and a watch directory to look for new .torrent files.

The only mandatory configuration is to set two environment variables for your PIA username and password. You must set the environment variables `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` to your login credentials. The container will connect to the Private Internet Access VPN servers in Netherlands by default.

### Required environment options
| Variable | Function | Example |
|----------|----------|-------|
|`OPENVPN_USERNAME`|Your login username for PIA|`OPENVPN_USERNAME=asdf`|
|`OPENVPN_PASSWORD`|Your login password for PIA|`OPENVPN_PASSWORD=asdf`|

### Network configuration options
| Variable | Function | Example |
|----------|----------|-------|
|`OPEN_VPN_CONFIG` | Sets the PIA endpoint to connect to. | `OPEN_VPN_CONFIG=UK Southampton`|
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

PS: `TRANSMISSION_BIND_ADDRESS_IPV4` will be overridden to the IP assigned to tunnel interface by PIA. This is to prevent leaking of the host IP.

## Building the container yourself
To build this container, clone the repository and cd into it.

### Build it:
```
$ cd /repo/location/docker-transmission-openvpn
$ docker build -t="docker-transmission-openvpn" .
```
### Run it:
```
$ docker run --privileged  -d \
              -v /your/storage/path/:/data \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 9091:9091 \
              docker-transmission-openvpn
```

As described in the "Run container from Docker registry" section, this will start a container with default settings. This means that you should have the folders "completed, incomplete and watch" in /your/storage/path, and pia-credentials.txt in /your/config/path.

### Issues
If you are having some issues running the local build then please ensure you are using the latest version of docker. Using the latest stable verison is always recommended. Support for older version is on a best-effort basis.

## Access the WebUI
But what's going on? My http://my-host:9091 isn't responding?
This is because the VPN is active, and since docker is running in a different ip range than your client the response to your request will be treated as "non-local" traffic and therefore be routed out through the VPN interface.

### How to fix this
There are several ways to fix this. You can pipe and do fancy iptables or ip route configurations on the host and in the Docker image. But I found that the simplest solution is just to proxy my traffic. Start a Nginx container like this:

```
$ docker run -d -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro -p 8080:8080 nginx
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
The container exposes /config as a volume. This is the directory where the supplied transmission and PIA credentials will be stored. If you have transmission authentication enabled and want scripts in another container to access and control the transmission-daemon, this can be a handy way to access the credentials.
For example, another container may pause or restrict transmission speeds while the server is streaming video.
