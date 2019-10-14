Another way is to use a docker env file where you can easily store all your env variables and maintain multiple configurations for different providers.
In the GitHub repository there is a provided [DockerEnv](https://github.com/haugene/docker-transmission-openvpn/blob/master/DockerEnv) file with all the current transmission and openvpn environment variables. You can use this to create local configurations
by filling in the details and removing the # of the ones you want to use.

Please note that if you pass in env. variables on the command line these will override the ones in the env file.

See explanation of variables above.
To use this env file, use the following to run the docker image:
```
$ docker run --cap-add=NET_ADMIN --device=/dev/net/tun -d \
              -v /your/storage/path/:/data \
              -v /etc/localtime:/etc/localtime:ro \
              --env-file /your/docker/env/file \
              -p 9091:9091 \
              haugene/transmission-openvpn
```
