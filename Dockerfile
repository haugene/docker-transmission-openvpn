# Transmission and OpenVPN
#
# Version 0.9

FROM phusion/baseimage:latest
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
RUN apt-get install -y supervisor
RUN apt-get install -y openvpn
RUN apt-get install -y curl
RUN apt-get install -y screen

# Create directories
RUN mkdir -p /var/log/supervisor

# Add configuration and scripts
ADD piaconfig/config.ovpn /etc/openvpn/config.ovpn
ADD piaconfig/credentials.txt /etc/openvpn/credentials.txt
ADD piaconfig/ca.crt /etc/openvpn/ca.crt
ADD piaconfig/crl.pem /etc/openvpn/crl.pem
ADD startOpenVPN.sh /etc/openvpn/start.sh
ADD transmissionSettings.json /etc/transmission-daemon/settings.json
ADD updateTransmissionPort.sh /etc/transmission-daemon/updatePort.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port and run supervisord
EXPOSE 9091
CMD ["/usr/bin/supervisord"]
