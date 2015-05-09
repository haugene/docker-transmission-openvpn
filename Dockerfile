# Transmission and OpenVPN
#
# Version 1.0

FROM ubuntu:14.04
MAINTAINER Kristian Haugene

VOLUME /data

# Update package sources list
RUN apt-get update

# Add transmission ppa repository for latest releases
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:transmissionbt/ppa

# Update packages and install software
RUN apt-get update
RUN apt-get install -y transmission-cli
RUN apt-get install -y transmission-common
RUN apt-get install -y transmission-daemon
RUN apt-get install -y openvpn
RUN apt-get install -y curl

VOLUME /config

# Add configuration and scripts
ADD piaconfig/* /etc/openvpn/
ADD piaconfig/ca.crt /etc/openvpn/ca.crt
ADD piaconfig/crl.pem /etc/openvpn/crl.pem
ADD transmission/defaultSettings.json /etc/transmission-daemon/settings.json
ADD transmission/updateTransmissionPort.sh /etc/transmission-daemon/updatePort.sh
ADD transmission/periodicUpdates.sh /etc/transmission-daemon/periodicUpdates.sh
ADD transmission/run.sh /etc/transmission-daemon/start.sh
ADD transmission/runUpdates.sh /etc/transmission-daemon/startPortUpdates.sh
ADD transmission/down.sh /etc/transmission-daemon/stop.sh
ADD runOpenVpn.sh /etc/openvpn/start.sh

# Expose port and run. Use baseimage-docker's init system
EXPOSE 9091
CMD ["/etc/openvpn/start.sh"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
