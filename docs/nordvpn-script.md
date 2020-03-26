## NORDVPN API

The update script is based on the NordVPN API. The API sends back the best recommended OpenVPN configuration file based on the filters given.

Available ENV variables in the container to define via the NordVPN API the file to use are:

| Variable           | Function                                                                                                                                                            | Example                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `NORDVPN_COUNTRY`  | Two character country code. See [/servers/countries](https://api.nordvpn.com/v1/servers/countries) for full list.                                                   | `NORDVPN_COUNTRY=US`          |
| `NORDVPN_CATEGORY` | Server type (P2P, Standard, etc). See [/servers/groups](https://api.nordvpn.com/v1/servers/groups) for full list. Use either `title` or `identifier` from the list. | `NORDVPN_CATEGORY=legacy_p2p` |
| `NORDVPN_PROTOCOL` | Either `tcp` or `udp`. (values identifier more available at https://api.nordvpn.com/v1/technologies, may need script adaptation)                                    | `NORDVPN_PROTOCOL=tcp`        |

The file is then downloaded using the API to find the best server according to the variables, here an albanian, using tcp:

* selecting server (limit answer to 1): [ANSWER]= https://api.nordvpn.com/v1/servers/recommendations?filters[country_id]=2&filters[servers_technologies][identifier]=openvpn_tcp&filters[servers_group][identifier]=legacy_group_category&limit=1
* download selected server's config: https://downloads.nordcdn.com/configs/files/ovpn_[NORDVPN_PROTOCOL]/servers/[ANSWER.0.HOSTNAME][] => https://downloads.nordcdn.com/configs/files/ovpn_tcp/servers/al9.nordvpn.com.tcp.ovpn

A possible evolution would be to check server's load to select the most available one.

* limit numbers of returned server to 10
* use https://api.nordvpn.com/server/stats to collect cpu's load
* select the more available server.
