from typing import Dict, List

from pydantic import BaseModel


class PiaServer(BaseModel):
    ip: str
    cn: str


class PiaRegion(BaseModel):
    id: str
    name: str
    country: str
    dns: str
    port_forward: bool
    servers: Dict[str, List[PiaServer]]


class PiaServerRespone(BaseModel):
    groups: Dict[str, List]
    regions: List[PiaRegion]


class PiaWireGuardConfig(BaseModel):
    status: str
    server_key: str
    server_port: int
    server_ip: str
    server_vip: str
    peer_ip: str
    peer_pubkey: str
    dns_servers: List[str]


class PiaTokenResponse(BaseModel):
    status: str
    token: str
