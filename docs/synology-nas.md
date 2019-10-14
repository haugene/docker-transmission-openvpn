Here are the steps to run it on a Synology NAS (Tested on DSM 6) :

- Connect as _admin_ to your Synology SSH
- Switch to root with command `sudo su -`
- Enter your _admin_ password when prompted
- Create a TUN.sh file anywhere in your synology file system by typing `vim /volume1/foldername/TUN.sh`
replacing _foldername_ with any folder you created on your Synology. You will also need to replace `foldername` for the commands in the remainder of this guide.
- Paste @timkelty 's script :
```
#!/bin/sh

# Create the necessary file structure for /dev/net/tun
if ( [ ! -c /dev/net/tun ] ); then
  if ( [ ! -d /dev/net ] ); then
    mkdir -m 755 /dev/net
  fi
  mknod /dev/net/tun c 10 200
  chmod 0755 /dev/net/tun
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
- Create your Docker container with the following command. Note the following things you should change or may want to consider changing:
  - If you'd like any Transmission options (for instance, stop seeding once a certain ratio has been reached) to persist across container restarts, now is the time to enter them by modifying the command below. See [here](https://haugene.github.io/docker-transmission-openvpn/arguments/#transmission_configuration_options) for details.
  - You must change the folder paths for the paths listed in the following command.
  - You must also specify the UID and GID of the user Transmission should run. The placeholder provided below almost certainly will not work on your system without modification. 
```
# Tested on DSM 6.1.4-15217 Update 1, Docker Package 17.05.0-0349
docker run \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    -d \
    -v /volume1/foldername/resolv.conf:/etc/resolv.conf \
    -v /volume1/yourpath/:/data \
    -e "OPENVPN_PROVIDER=PIA" \
    -e "OPENVPN_CONFIG=CA\ Toronto" \
    -e "OPENVPN_USERNAME=XXXXX" \
    -e "OPENVPN_PASSWORD=XXXXX" \
    -e "LOCAL_NETWORK=192.168.0.0/24" \
    -e "OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60" \
    -e "PGID=100" \
    -e "PUID=1234" \
    -p 9091:9091 \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name "transmission-openvpn-syno" \
    haugene/transmission-openvpn:latest
```
- To make it work after a nas restart, create an automated task in your synology web interface : go to **Settings Panel > Task Scheduler ** create a new task that run `/volume1/foldername/TUN.sh` as root (select '_root_' in 'user' selectbox). This task will start module that permit the container to run, you can make a task that run on startup. These kind of task doesn't work on my nas so I just made a task that run every minute.
- Enjoy