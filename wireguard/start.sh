#! /bin/bash

# Exit on error
set -e

if [[ -n "$REVISION" ]]; then
  echo "Starting container with revision: $REVISION"
fi
if [[ -n "$BASE_REVISION" ]]; then
  echo "Base image revision: $BASE_REVISION"
fi

echo "Current public IP is:"
curl --silent -w "\n" ipecho.net/plain

if ip netns ls | grep -q "physical"
then
    # Dangling network from previous run, clean up
    echo "Clean up dangling network namespaces"
    ip -all netns delete
fi

# Grab information from the default interface set up in the container
GW=$(/sbin/ip route list match 0.0.0.0 | awk '{print $3}')
INT=$(/sbin/ip route list match 0.0.0.0 | awk '{print $5}')
INT_IP=$(ip -f inet addr show "$INT" | awk '/inet / {print $2}')
INT_BRD=$(ip -f inet addr show "$INT" | awk '/inet / {print $4}')

echo "Found default container interface, will use this in setup:"
echo "Interface: $INT"
echo "Gateway: $GW"
echo "Interface address: $INT_IP"
echo "Interface broadcast: $INT_BRD"

# Override DNS to Cloudflare
cat /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Create a "physical" network namespace and move our eth0 there
ip netns ls
ip netns add physical
ip link set eth0 netns physical

# Create wireguard interface in physical namespace and move it to the default namespace
ip -n physical link add wg0 type wireguard
ip -n physical link set wg0 netns 1

# Restore IP and route configuration for the default interface, start it
ip -n physical addr add "$INT_IP" dev "$INT" brd "$INT_BRD"
ip -n physical link set "$INT" up
#ip -n physical link set lo up
ip -n physical route add default via "$GW" dev "$INT"

#
# Setting up Wireguard
# We need to make the wg0 interface separately to do the namespace linking
# and we can't use wg-quick after that. So the rest is done "manually".
#
address=$(grep "Address" "$CONFIG_FILE" | awk '{print $NF}' | cut -d, -f1)
#dns=$(grep "DNS" "$config_file" | awk '{print $NF}')

ip addr add "$address" dev wg0

stripped_config_file=$(mktemp)
wg-quick strip "$CONFIG_FILE" > "$stripped_config_file"

echo "Will use wg config from $stripped_config_file"
wg setconf wg0 "$stripped_config_file"
ip link set wg0 up
#ip link set lo up
ip route add default dev wg0

#
# Wireguard interface is now set up and should be connected
#
echo "Wireguard is up - new IP:"
curl --silent -w "\n" ipecho.net/plain

# Create a veth link pair, one interface in each namespace
ip link add veth1 type veth peer name veth2 netns physical

# Set their IPs, CIDR with only two addresses to limit ip route ranges
ip addr add 10.10.13.36/31 dev veth1
ip -n physical addr add 10.10.13.37/31 dev veth2

# Start the veth interfaces
ip link set veth1 up
ip -n physical link set veth2 up

# Start a reverse proxy in the physical namespace
ip netns exec physical nginx -c /opt/nginx/server.conf

# Make sure TRANSMISSION_HOME exists and create/update settings.json
mkdir -p "$TRANSMISSION_HOME"
python3 /opt/transmission/updateSettings.py /opt/transmission/default-settings.json ${TRANSMISSION_HOME}/settings.json || exit 1

# Support running Transmission as non-root (and set permissions on folders)
. /opt/transmission/userSetup.sh

exec su --preserve-environment ${RUN_AS} -s /bin/bash -c "/usr/local/bin/transmission-daemon --foreground -g ${TRANSMISSION_HOME}"
