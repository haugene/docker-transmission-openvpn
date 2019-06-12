### Running on ARM (Raspberry PI)
Since the Raspberry PI runs on an ARM architecture instead of x64, the existing x64 images will not
work properly. There are 2 additional Dockerfiles created. The Dockerfiles supported by the Raspberry PI are Dockerfile.armhf -- there is
also an example docker-compose-armhf file that shows how you might use Transmission/OpenVPN and the
corresponding nginx reverse proxy on an RPI machine.
You can use the `latest-armhf` tag for each images (see docker-compose-armhf.yml) or build your own images using Dockerfile.armhf.