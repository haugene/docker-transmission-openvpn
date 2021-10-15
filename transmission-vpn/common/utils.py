import subprocess
from typing import Tuple



def find_lan_gateway_and_interface() -> Tuple[str, str]:
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
    
    return (lan_gateway, lan_interface)