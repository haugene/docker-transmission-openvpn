#### Use Google DNS servers
Some have encountered problems with DNS resolving inside the docker container.
This causes trouble because OpenVPN will not be able to resolve the host to connect to.
If you have this problem use dockers --dns flag to override the resolv.conf of the container.
For example use googles dns servers by adding --dns 8.8.8.8 --dns 8.8.4.4 as parameters to the usual run command.

#### Restart container if connection is lost
If the VPN connection fails or the container for any other reason loses connectivity, you want it to recover from it. One way of doing this is to set environment variable `OPENVPN_OPTS=--inactive 3600 --ping 10 --ping-exit 60` and use the --restart=always flag when starting the container. This way OpenVPN will exit if ping fails over a period of time which will stop the container and then the Docker deamon will restart it.

#### Reach sleep or hybernation on your host if no torrents are active
By befault Transmission will always [scrape](https://en.wikipedia.org/wiki/Tracker_scrape) trackers, even if all torrents have completed their activities, or they have been paused manually. This will cause Transmission to be always active, therefore never allow your host server to be inactive and go to sleep/hybernation/whatever. If this is something you want, you can add the following variable when creating the container. It will turn off a hidden setting in Tranmsission which will stop the application to scrape trackers for paused torrents. Transmission will become inactive, and your host will reach the desidered state.
```
-e "TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED=false"
```
#### Running it on a NAS
Several popular NAS platforms supports Docker containers. You should be able to set up and configure this container using their web interfaces. Remember that you need a TUN/TAP device to run the container. To set up the device it's probably simplest to install a OpenVPN package for the NAS. This should set up the device. If not, there are some more detailed instructions below.

#### Questions?
If you are having issues with this container please submit an issue on GitHub.
Please provide logs, docker version and other information that can simplify reproducing the issue.
Using the latest stable version of Docker is always recommended. Support for older version is on a best-effort basis.