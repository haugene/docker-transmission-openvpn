import subprocess
import os
from providers.common.utils import find_lan_gateway_and_interface
from providers.pia import main as pia

WIREGUARD_CONFIG_PATH = "/etc/wireguard/wg0.conf"
USER_CONFIG_PATH = "/etc/transmission-vpn/wireguard/wg0.conf"

vpn_provider = os.getenv("VPN_PROVIDER")
if vpn_provider and vpn_provider.lower() == "pia":
    print("Running custom startup script for PIA")
    pia.setup()

    # Want to do something like this ?
    #provider = importlib.import_module(f"providers.{vpn_provider.lower()}.main")
    #provider.setup()

else:
    assert os.path.isfile(USER_CONFIG_PATH), "No config file mounted"

    with open(USER_CONFIG_PATH) as user_config_file:
        config_lines = user_config_file.readlines()

    interface_index_line = config_lines.index("[Interface]\n")
    peer_index_line = config_lines.index("[Peer]\n")
    assert interface_index_line < peer_index_line, "Malformed config file, expecting Interface before Peer definition"

    interface_lines = config_lines[interface_index_line:peer_index_line]
    peer_lines = config_lines[peer_index_line:]

    local_network = os.getenv("LOCAL_NETWORK")
    if local_network:
        lan_gateway, lan_interface = find_lan_gateway_and_interface()
        post_up = (
            f"PostUp = ip route add {local_network} via {lan_gateway} dev {lan_interface}"
        )
        interface_lines.append(post_up)

    with open(WIREGUARD_CONFIG_PATH, "w") as config_file:
        config_file.writelines(config_lines)


assert os.path.isfile(WIREGUARD_CONFIG_PATH), "Init code ran without producing wg0.conf"
print("\nStarting WireGuard...")
try:
    vpn_start = subprocess.run(
        ["wg-quick", "up", "wg0"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=True,
    )
    print(vpn_start.stdout)
    print("WireGuard connection successfully established")
except subprocess.CalledProcessError as e:
    print(e.output)
    raise e
