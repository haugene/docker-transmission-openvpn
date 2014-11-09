# Transmission and OpenVPN
#
# Version 0.9

FROM ubuntu:14.04
MAINTAINER Kristian Haugene

VOLUME /data

RUN apt-get update
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:transmissionbt/ppa
RUN apt-get update
RUN apt-get install -y transmission-cli
RUN apt-get install -y transmission-common
RUN apt-get install -y transmission-daemon
RUN apt-get install -y supervisor
RUN apt-get install -y openvpn
RUN mkdir -p /var/log/supervisor

# Not generally in use. But nice when starting up container interactively
RUN apt-get install -y screen

ADD piaconfig/config.ovpn /etc/openvpn/config.ovpn
ADD piaconfig/credentials.txt /etc/openvpn/credentials.txt
ADD piaconfig/ca.crt /etc/openvpn/ca.crt
ADD piaconfig/crl.pem /etc/openvpn/crl.pem
ADD startOpenVPN.sh /etc/openvpn/start.sh
ADD transmissionSettings.json /etc/transmission-daemon/settings.json
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9091

CMD ["/usr/bin/supervisord"]
