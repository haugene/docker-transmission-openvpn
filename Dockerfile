# Transmission and OpenVPN
#
# Version 1.0

FROM ubuntu:14.04
MAINTAINER Kristian Haugene

VOLUME /data

# Update packages and install software
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && add-apt-repository ppa:transmissionbt/ppa \
    && apt-get update \
    && apt-get install -y transmission-cli transmission-common transmission-daemon openvpn curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

# Add configuration and scripts
ADD piaconfig/config.ovpn /etc/openvpn/config.ovpn
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
