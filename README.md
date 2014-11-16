Private Internet Access OpenVPN - Transmission
===
This Docker container lets you run Transmission with WebUI while connecting to PIA VPN. It updates Transmission hourly with assigned open port from PIA. Please read the instructions below.

# Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it. To run the container use this command:

```
docker run --privileged  -d -v /your/storage/path/:/data -v /your/config/path/:/config -p 9091:9091 haugene/transmission-openvpn
```

As you can see, the container expects two volumes to be mounted. One is used for storing your downloads from Transmission, and the other provides configurations. The container comes with a default Transmission settings.json file that expects the folders "completed, incomplete and watch" to be present in /your/storage/path (aka /data). This is where Transmission will store your downloads, incomplete downloads and a watch directory to look for new .torrent files.

The only mandatory configuration is a pia-credentials.txt file that needs to be put in /your/config/path/ directory. In the file you supply your username and password for Private Internet Access VPN connections. The file should have two lines; your username on line 1 and your password on line 2. The container will connect to the Private Internet Access VPN servers in Netherlands by default.

NB: Instructions on how to use your own Transmission settings, and how to connect to the WebUI, is further down in the README.

# Building the container yourself
To build this container, clone the repository and cd into it.

### Build it:
```
cd /repo/location/docker-transmission-openvpn
docker build -t="docker-transmission-openvpn" .
```
### Run it:
```
docker run --privileged  -d -v /your/storage/path/:/data -v /your/config/path/:/config -p 9091:9091 docker-transmission-openvpn
```

As described in the "Run container from Docker registry" section, this will start a container with default settings. This means that you should have the folders "completed, incomplete and watch" in /your/storage/path, and pia-credentials.txt in /your/config/path.

### But I want to provide my own Transmission settings!
OK, so you're advanced. If you want to change the Transmission settings from the defaults, create your own settings.json file or base it on the default config. Then make the container use it by adding a folder called "transmission" in /your/config/path and place your settings.json there.

On container startup it checks for /config/transmission/settings.json and uses /config/transmission as config directory if the settings file is present. This also means that Transmission will store its state here, so that you don't have to add torrents again when the container restarts.

If you enable rpc-authentication in your Transmission settings, you need to provide your credentials in a file called transmission-credentials.txt and place it in your config directory. The file is on the same format as pia-credentials.txt, username and password. This is needed because we run a script hourly to get an open port, making us connectable, from PIA. To set this port in Transmission the script needs to know your rpc-authentication username and password.

NB: Do not change the settings.json file while container is running. Transmission persist its config on shutdown, and this will override your changes. Stop the container, do configurations, then start it again.

### Access the WebUI
But what's going on? My http://my-host:9091 isn't responding?
This is because the VPN is active, and since docker is running in a different ip range than your client the response to your request will be treated as "non-local" traffic and therefore be routed out through the VPN interface.

### How to fix this
There are several ways to fix this. You can pipe and do fancy iptables or ip route configurations on the host and in the Docker image. But I found that the simplest solution is just to proxy my traffic. Start a Nginx container like this:

```
docker run -d -v /path/to/nginx.conf:/etc/nginx.conf:ro -p 8080:80 nginx
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

### What if I want to run the container interactively.
If you want do have access inside the container while running, do like this.

```
docker run --privileged -v /mnt/disk1/Torrents/:/data -v /your/config/path/:/config -p 9091:9091 -it --entrypoint=/bin/bash docker-transmission-openvpn
```

This will start the container and give you a bash shell to work from. The container has screen installed, so you can use screen to start the init system which starts openVPN and Transmission. Then you can detach from screen and continue to use bash inside the running container. If you're unfamiliar with screen, read up on it. The commands are as follows:

``` 
screen
```
Accept the terms, then run my_init and detach.

```
/sbin/my_init
CTRL+A + d
```
You should now be detached and both services should be running.
