import os
import subprocess

from models import *
from utils import find_region, get_pia_servers, get_pia_token, register_client

#
# A bit of a mess fixing the LOCAL_NETWORK stuff
#
default_route = subprocess.run(
    ["ip", "route", "list", "match", "0.0.0.0"],
    capture_output=True,
    text=True,
    check=True,
).stdout.strip()
route_parts = default_route.split()

# Output from the command above should be on the form:
# default via 172.23.0.1 dev eth0
assert (
    route_parts[1] == "via" and route_parts[3] == "dev"
), f"Unexpected output from ip route list: {default_route}"

# Get the gateway and interface
lan_gateway = route_parts[2]
lan_interface = route_parts[4]

#
# Find the server to connect to
#
preferred_region = os.getenv("VPN_REGION", "DE Frankfurt")
print(f"Will try to connect to region {preferred_region}")

pia_servers = get_pia_servers()
pia_region = find_region(pia_servers, preferred_region)
pia_server = pia_region.servers["wg"][0]

#
# Generate WireGuard keys and config
#
private_key = subprocess.run(
    ["wg", "genkey"], capture_output=True, text=True, check=True
).stdout.strip()
public_key = subprocess.run(
    ["wg", "pubkey"], capture_output=True, text=True, check=True, input=private_key
).stdout.strip()

pia_token = get_pia_token(os.getenv("VPN_USERNAME"), os.getenv("VPN_PASSWORD"))
wg_config = register_client(pia_server, pia_token, public_key)

local_network = os.getenv("LOCAL_NETWORK")
post_up = ""
if local_network:
    post_up = (
        f"PostUp = ip route add {local_network} via {lan_gateway} dev {lan_interface}"
    )
else:
    print(
        "You have not specified the LOCAL_NETWORK variable and might get issues connecting to the WebUI."
    )

#
# Concatenate the config in a wg-quick format
#
wg_quick_config = f"""
[Interface]
Address = {wg_config.peer_ip}
PrivateKey = {private_key}
DNS = {wg_config.dns_servers[0]}
{post_up}

[Peer]
PersistentKeepalive = 25
PublicKey = {wg_config.server_key}
AllowedIPs = 0.0.0.0/0
Endpoint = {wg_config.server_ip}:{wg_config.server_port}
"""

#
# Write it to file and start WireGuard
#
with open("/etc/wireguard/wg0.conf", "w") as config_file:
    config_file.write(wg_quick_config)

print("\nStarting WireGuard...")
vpn_start = subprocess.run(
    ["wg-quick", "up", "wg0"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    check=True,
)
print(vpn_start.stdout)
print("WireGuard connection successfully established")
