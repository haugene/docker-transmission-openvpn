## COMING SOON

**NOTE:** This page is just moved from it's previous location. A re-write is coming and I know that
there are links to this page that promises more than what's here now. I'm [on it (#1558)](https://github.com/haugene/docker-transmission-openvpn/issues/1558)


## Access the WebUI
But what's going on? My http://my-host:9091 isn't responding?
This is because the VPN is active, and since docker is running in a different ip range than your client the response
to your request will be treated as "non-local" traffic and therefore be routed out through the VPN interface.

### How to fix this
The container supports the `LOCAL_NETWORK` environment variable. For instance if your local network uses the IP range 192.168.0.0/24 you would pass `-e LOCAL_NETWORK=192.168.0.0/24`.

Alternatively you can reverse proxy the traffic through another container, as that container would be in the docker range. There is a reverse proxy being built with the container. You can run it using the command below or have a look in the repository proxy folder for inspiration for your own custom proxy.

```
$ docker run -d \
      --link <transmission-container>:transmission \
      -p 8080:8080 \
      --name transmission-openvpn-proxy \
      haugene/transmission-openvpn-proxy
```
## Access the RPC

You need to add a / to the end of the URL to be able to connect. Example: http://my-host:9091/transmission/rpc/

## Controlling Transmission remotely
The container exposes /config as a volume. This is the directory where the supplied transmission and OpenVPN credentials will be stored.
If you have transmission authentication enabled and want scripts in another container to access and
control the transmission-daemon, this can be a handy way to access the credentials.
For example, another container may pause or restrict transmission speeds while the server is streaming video.

## Network best practices
All VPN's and networking can have flaws.  Before using your Transmission/OpenVPN stack you should plan to test for DNS and traffic leaks.
A simple way to do this is via https://www.ipleak.net but other services are available.  Once you access the page you will see your web browser information about IP addresses and DNS servers.  If you scroll down you will find a section that says "Torrent Address Detection"  Click on the "Activate" button and you will be given a magnet link that you can add to Transmission.  Once added go back to the IpLeak.net page and you will see information about your torrent connection.  If you see anything that is not traveling over your VPN you are LEAKING.  If this is over IPv6 in a dual stack (IPv4+IPv6) environment you need to disable IPv6 in the network used by the container.

## Disabling IPv6 in a dual stack network
In Docker Compose you can simply add the following to your YAML file and the container will be built with IPv6 disabled.  If your VPN provider works or provides a tunnel over IPv6 you cans simply change "false" to "true" or remove the section.

```
        networks: 
          - transmission_default
```

```
networks:
  transmission_default:
    name: transmission_default
    enable_ipv6: false
```

Using Docker Run (Podman should work in a similar fashion using the podman command in place of docker) you will have to do this in two steps.  First you must create the Network and then you need to connect the container to the network you created.

```
$ docker network create --ipv6=false transmission_default
```
Then add the following line to your docker run configuration so that the container will use the previously created network.
```
             --network transmission_default
```
