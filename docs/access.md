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
      haugene/transmission-openvpn-proxy
```
## Access the RPC

You need to add a / to the end of the URL to be able to connect. Example: http://my-host:9091/transmission/rpc/

## Controlling Transmission remotely
The container exposes /config as a volume. This is the directory where the supplied transmission and OpenVPN credentials will be stored.
If you have transmission authentication enabled and want scripts in another container to access and
control the transmission-daemon, this can be a handy way to access the credentials.
For example, another container may pause or restrict transmission speeds while the server is streaming video.