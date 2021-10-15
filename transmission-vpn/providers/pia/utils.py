import requests
from forcediphttpsadapter.adapters import ForcedIPHTTPSAdapter
from .models import *


def register_client(server: PiaServer, token: str, pub_key: str) -> PiaWireGuardConfig:
    # https://stackoverflow.com/questions/18578439/using-requests-with-tls-doesnt-give-sni-support/18579484#18579484
    session = requests.Session()
    session.mount(f"https://{server.cn}:1337", ForcedIPHTTPSAdapter(dest_ip=server.ip))

    params = {
        "pt": token,
        "pubkey": pub_key,
    }
    response = session.get(
        f"https://{server.cn}:1337/addKey",
        verify="providers/pia/ca.rsa.4096.crt",
        headers={"Host": server.cn},
        params=params,
        timeout=5,
    )
    response.raise_for_status()
    return PiaWireGuardConfig.parse_obj(response.json())


def get_pia_token(username: str, password: str) -> str:
    # Fail if either user or password is None
    assert (
        username and password
    ), "ERROR: Either username or password is missing, cannot connect."

    # Call PIA and fetch a token
    pia_token_response = requests.get(
        "https://www.privateinternetaccess.com/gtoken/generateToken",
        auth=(username, password),
        timeout=5,
    )
    pia_token_response.raise_for_status()
    pia_token = PiaTokenResponse.parse_obj(pia_token_response.json())

    assert pia_token.status == "OK", "Something went wrong fetching token from PIA"
    return pia_token.token


def get_pia_servers() -> PiaServerRespone:
    pia_response = requests.get(
        "https://serverlist.piaservers.net/vpninfo/servers/v6", timeout=5
    )
    pia_response.raise_for_status()
    return PiaServerRespone.parse_raw(pia_response.text.splitlines()[0])


def find_region(server_repsonse: List[PiaServerRespone], region_name: str) -> PiaRegion:
    for region in server_repsonse.regions:
        if region.name == region_name:
            return region

    raise KeyError(f"Could not find region {region_name} in region list")
