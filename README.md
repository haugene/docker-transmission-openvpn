# Transmission with WebUI and OpenVPN
Docker container which runs Transmission torrent client with WebUI while connecting to OpenVPN.
It bundles certificates and configurations for the following VPN providers:
* Anonine
* BTGuard
* Cryptostorm
* FrootVPN
* FrostVPN
* HideMe
* HideMyAss
* IntegrityVPN
* IPVanish
* Ivacy
* IVPN
* Newshosting
* NordVPN
* OVPN
* Private Internet Access
* PrivateVPN
* PureVPN
* SlickVPN
* TigerVPN
* TorGuard
* UsenetServerVPN

When using PIA as provider it will update Transmission hourly with assigned open port. Please read the instructions below.

## Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it.
To run the container use this command:

```
$ docker run --privileged  -d \
              -v /your/storage/path/:/data \
              -v /etc/localtime:/etc/localtime:ro \
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
By default a folder named transmission-home will also be created under /data, this is where Transmission stores its state.


### Required environment options
| Variable | Function | Example |
|----------|----------|-------|
|`OPENVPN_PROVIDER` | Sets the OpenVPN provider to use. | `OPENVPN_PROVIDER=provider`. Supported providers are `PIA`, `BTGUARD`, `TIGER`, `FROOT`, `TORGUARD`, `NEWSHOSTING`, `NORDVPN`, `USENETSERVER`, `INTEGRITYVPN`, `IPVANISH`, `ANONINE`, `HIDEME`, `PUREVPN`, `HIDEMYASS`, `PRIVATEVPN`, `IVPN`, `OVPN`, `SLICKVPN`, `IVACY` and `CRYPTOSTORM`|
|`OPENVPN_USERNAME`|Your OpenVPN username |`OPENVPN_USERNAME=asdf`|
|`OPENVPN_PASSWORD`|Your OpenVPN password |`OPENVPN_PASSWORD=asdf`|

### Network configuration options
| Variable | Function | Example |
|----------|----------|-------|
|`OPENVPN_CONFIG` | Sets the OpenVPN endpoint to connect to. | `OPENVPN_CONFIG=UK Southampton`|
|`OPENVPN_OPTS` | Will be passed to OpenVPN on startup | See [OpenVPN doc](https://openvpn.net/index.php/open-source/documentation/manuals/65-openvpn-20x-manpage.html) |
|`LOCAL_NETWORK` | Sets the local network that should have access. | `LOCAL_NETWORK=192.168.0.0/24`|

### Transmission configuration options

You may override transmission options by setting the appropriate environment variable.

The environment variables are the same name as used in the transmission settings.json file
and follow the format given in these examples:

| Transmission variable name | Environment variable name |
|----------------------------|---------------------------|
| `speed-limit-up` | `TRANSMISSION_SPEED_LIMIT_UP` |
| `speed-limit-up-enabled` | `TRANSMISSION_SPEED_LIMIT_UP_ENABLED` |
| `ratio-limit` | `TRANSMISSION_RATIO_LIMIT` |
| `ratio-limit-enabled` | `TRANSMISSION_RATIO_LIMIT_ENABLED` |

As you can see the variables are prefixed with `TRANSMISSION_`, the variable is capitalized, and `-` is converted to `_`.

PS: `TRANSMISSION_BIND_ADDRESS_IPV4` will be overridden to the IP assigned to your OpenVPN tunnel interface.
This is to prevent leaking the host IP.

## Access the WebUI
But what's going on? My http://my-host:9091 isn't responding?
This is because the VPN is active, and since docker is running in a different ip range than your client the response
to your request will be treated as "non-local" traffic and therefore be routed out through the VPN interface.

### How to fix this
There are several ways to fix this. The container supports the `LOCAL_NETWORK` environment variable. For instance if your local network uses the IP range 192.168.0.0/24 you would pass `-e LOCAL_NETWORK=192.168.0.0/24`. Alternatively just proxy the traffic.

#### Use preconfigured image
You can use the proxy image haugene/transmission-openvpn-proxy that comes with a config that is configurable through environment variables.

Start it like this:

```
$ docker run -d \
      --link <transmission-container>:transmission \
      -p 8080:8080 \
      haugene/transmission-openvpn-proxy
```
You can change to bind another port on your host by changing it to `-p 9090:8080` etc.

#### Use a custom proxy config

If you want to run the proxy with your own configuration you can do that by doing something like this.

```
$ docker run -d \
      -v /path/to/your/nginx.conf:/etc/nginx/nginx.conf:ro \
      -p 8080:8080 \
      nginx
```

#### Finally
Based on the examples above, Transmission WebUI should now be avaliable at "your.host.ip.addr:8080/transmission/web/". See the docker-compose.yml file for an example on how to run the two containers using compose.

## Known issues, tips and tricks

#### Use Google DNS servers
Some have encountered problems with DNS resolving inside the docker container.
This causes trouble because OpenVPN will not be able to resolve the host to connect to.
If you have this problem use dockers --dns flag to override the resolv.conf of the container.
For example use googles dns servers by adding --dns 8.8.8.8 --dns 8.8.4.4 as parameters to the usual run command.

#### Restart container if connection is lost
If the VPN connection fails or the container for any other reason loses connectivity, you want it to recover from it. One way of doing this is to set environment variable `OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60` and use the --restart=always flag when starting the container. This way OpenVPN will exit if ping fails over a period of time which will stop the container and then the Docker deamon will restart it.

#### Running it on a NAS
Several popular NAS platforms supports Docker containers. You should be able to set up and configure this container using their web interfaces. Remember that you need a TUN/TAP device to run the container. To set up the device it's probably simplest to install a OpenVPN package for the NAS. This should set up the device. If not, there are some more detailed instructions below.

#### Questions?
If you are having issues with this container please submit an issue on GitHub.
Please provide logs, docker version and other information that can simplify reproducing the issue.
Using the latest stable verison of Docker is always recommended. Support for older version is on a best-effort basis.

## Adding new providers
If your VPN provider is not in the list of supported providers you could always create an issue on GitHub and see if someone could add it for you. But if you're feeling up for doing it yourself, here's a couple of pointers.

You clone this repository and create a new folder under "openvpn" where you put the .ovpn files your provider gives you. Depending on the structure of these files you need to make some adjustments. For example if they come with a ca.crt file that is referenced in the config you need to update this reference to the path it will have inside the container (which is /etc/openvpn/...). You also have to set where to look for your username/password.

There is a script called adjustConfigs.sh that could help you. After putting your .ovpn files in a folder, run that script with your folder name as parameter and it will try to do the changes descibed above. If you use it or not, reading it might give you some help in what you're looking to change in the .ovpn files.

Once you've finished modifying configs, you build the container and run it with OPENVPN_PROVIDER set to the name of the folder of configs you just created (it will be lowercased to match the folder names). And that should be it!

So, you've just added your own provider and you're feeling pretty good about it! Why don't you fork this repository, commit and push your changes and submit a pull request? Share your provider with the rest of us! :) Please submit your PR to the dev branch in that case.

### Using a custom provider

If you want to run the image with your own provider without building a new image, that is also possible. For some providers, like AirVPN, the .ovpn files are generated per user and contains credentials. They should not be added to a public image. This is what you do:

Add a new volume mount to your `docker run` command that mounts your config file:
`-v /path/to/your/config.ovpn:/etc/openvpn/custom/default.ovpn`

Then you can set `OPENVPN_PROVIDER=CUSTOM`and the container will use the config you provided. If you are using AirVPN or other provider with credentials in the config file, you still need to set `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` as this is required by the startup script. They will not be read by the .ovpn file, so you can set them to whatever.

Note that you still need to modify your .ovpn file as described in the previous section. If you have an separate ca.crt file your volume mount should be a folder containing both the ca.crt and the .ovpn config.

## Building the container yourself
To build this container, clone the repository and cd into it.

### Build it:
```
$ cd /repo/location/docker-transmission-openvpn
$ docker build -t transmission-openvpn .
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
              transmission-openvpn
```

This will start a container as described in the "Run container from Docker registry" section.

## Controlling Transmission remotely
The container exposes /config as a volume. This is the directory where the supplied transmission and OpenVPN credentials will be stored.
If you have transmission authentication enabled and want scripts in another container to access and
control the transmission-daemon, this can be a handy way to access the credentials.
For example, another container may pause or restrict transmission speeds while the server is streaming video.

## Running on ARM (Raspberry PI)
Since the Raspberry PI runs on an ARM architecture instead of x64, the existing x64 images will not 
work properly. To support users that wish to run this container on a Raspberry Pi, there are 2 additional 
Dockerfiles created. The Dockerfiles supported by the Raspberry PI are Dockerfile.armhf -- there is 
also an example docker-compose-armhf file that shows how you might use Transmission/OpenVPN and the 
corresponding nginx reverse proxy on an RPI machine.

## Make it work on Synology NAS
Here are the steps to run it on a Synology NAS (Tested on DSM 6) :

- Connect as _admin_ to your Synology SSH
- Switch to root with command `sudo su -`
- Enter your _admin_ password when prompted
- Create a TUN.sh file anywhere in your synology file system by typing `vim /volume1/foldername/TUN.sh`
replacing _foldername_ with any folder you created on your Synology
- Paste @timkelty 's script :
```
#!/bin/sh

# Create the necessary file structure for /dev/net/tun
if ( [ ! -c /dev/net/tun ] ); then
	if ( [ ! -d /dev/net ] ); then
		mkdir -m 755 /dev/net
	fi
	mknod /dev/net/tun c 10 200
fi

# Load the tun module if not already loaded
if ( !(lsmod | grep -q "^tun\s") ); then
	insmod /lib/modules/tun.ko
fi
```
- Save the file with [escape] + `:wq!`
- Go in the folder containing your script : `cd /volume1/foldername/`
- Check permission with `chmod 0755 TUN.sh`
- Run it with `./TUN.sh`
- Return to initial directory typing `cd`
- Create the DNS config file by typing `vim /volume1/foldername/resolv.conf`
- Paste the following lines :
```
nameserver 8.8.8.8
nameserver 8.8.4.4
```
- Save the file with [escape] + `:wq!`
- Create your docker container with a classic command like `docker run --privileged -d -v /volume1/foldername/resolv.conf:/etc/resolv.conf -v /volume1/yourpath/:/data -e "OPENVPN_PROVIDER=PIA" -e "OPENVPN_CONFIG=Netherlands" -e "OPENVPN_USERNAME=XXXXX" -e "OPENVPN_PASSWORD=XXXXX" -p 9091:9091 haugene/transmission-openvpn -name TransmissionVPN`
- To make it work after a nas restart, create an automated task in your synology web interface : go to **Settings Panel > Task Scheduler ** create a new task that run `/volume1/foldername/TUN.sh` as root (select '_root_' in 'user' selectbox). This task will start module that permit the container to run, you can make a task that run on startup. These kind of task doesn't work on my nas so I just made a task that run every minute.
- Enjoy

## systemd Integration

On many modern linux systems, including Ubuntu, systemd can be used to start the transmission-openvpn at boot time, and restart it after any failure.

Save the following as `/etc/systemd/system/transmission-openvpn.service`, and replace the OpenVPN PROVIDER/USERNAME/PASSWORD directives with your settings, and add any other directives that you're using.

This service is assuming that there is a `bittorrent` user set up with a home directory at `/home/bittorrent/`. The data directory will be mounted at `/home/bittorrent/data/`. This can be changed to whichever user and location you're using.

OpenVPN is set to exit if there is a connection failure. OpenVPN exiting triggers the container to also exit, then the `Restart=always` definition in the `transmission-openvpn.service` file tells systems to restart things again.

```
[Unit]
Description=haugene/transmission-openvpn docker container
After=docker.service
Requires=docker.service

[Service]
User=bittorrent
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill transmission-openvpn
ExecStartPre=-/usr/bin/docker rm transmission-openvpn
ExecStartPre=/usr/bin/docker pull haugene/transmission-openvpn
ExecStart=/usr/bin/docker run \
        --name transmission-openvpn \
        --privileged \
        -v /home/bittorrent/data/:/data \
        -e "OPENVPN_PROVIDER=TORGUARD" \
        -e "OPENVPN_USERNAME=bittorrent@example.com" \
        -e "OPENVPN_PASSWORD=hunter2" \
        -e "OPENVPN_CONFIG=Netherlands" \
        -e "OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60" \
        -e "TRANSMISSION_UMASK=0" \
        -p 9091:9091 \
        --dns 8.8.8.8 \
        --dns 8.8.4.4 \
        haugene/transmission-openvpn
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Then enable and start the new service with:

```
$ sudo systemctl enable /etc/systemd/system/transmission-openvpn.service
$ sudo systemctl restart transmission-openvpn.service
```

If it is stopped or killed in any fashion, systemd will restart the container. If you do want to shut it down, then run the following command and it will stay down until you restart it.

```
$ sudo systemctl stop transmission-openvpn.service
# Later ...
$ sudo systemctl start transmission-openvpn.service
```
