## COMING SOON

**NOTE:** This page is just moved from it's previous location. A re-write is coming.
I'm [on it (#1558)](https://github.com/haugene/docker-transmission-openvpn/issues/1558)

### NORDVPN

The update script is based on the NordVPN API. The API sends back the best recommended OpenVPN configuration file based on the filters given.

You have to use your service credentials instead of your regular email and password. They can be found [here](https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/).

Available ENV variables in the container to define via the NordVPN API the file to use are:

| Variable           | Function                                                                                                                                                            | Example                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `NORDVPN_COUNTRY`  | Two character country code. See [/servers/countries](https://api.nordvpn.com/v1/servers/countries) for full list.                                                   | `NORDVPN_COUNTRY=US`          |
| `NORDVPN_CATEGORY` | Server type (P2P, Standard, etc). See [/servers/groups](https://api.nordvpn.com/v1/servers/groups) for full list. Use either `title` or `identifier` from the list. | `NORDVPN_CATEGORY=legacy_p2p` |
| `NORDVPN_PROTOCOL` | Either `tcp` or `udp`. (values identifier more available at https://api.nordvpn.com/v1/technologies, may need script adaptation)                                    | `NORDVPN_PROTOCOL=tcp`        |
| `NORDVPN_SERVER` | Set VPN server FQDN to use, bypasses API recommendations and downloads server's config file. | NORDVPN_SERVER= sg460.nordvpn.com|

The file is then downloaded using the API to find the best server according to the variables, here an albanian, using tcp:

* selecting server (limit answer to 1): [ANSWER]= https://api.nordvpn.com/v1/servers/recommendations?filters[country_id]=2&filters[servers_technologies][identifier]=openvpn_tcp&filters[servers_group][identifier]=legacy_group_category&limit=1
* download selected server's config: https://downloads.nordcdn.com/configs/files/ovpn_[NORDVPN_PROTOCOL]/servers/[ANSWER.0.HOSTNAME][] => https://downloads.nordcdn.com/configs/files/ovpn_tcp/servers/al9.nordvpn.com.tcp.ovpn

One optional ENV var NORDVPN_TESTS can take value from 1 to 4. Expected generic results are written to logs.

| NORDVPN_TESTS | Comment | 
| --------------------- | --------------------- | 
| 1 | Test when nothing is set: All NORDVPN_{COUNTRY, PROTOCOL, CATEGORY} are not set |
| 2 | Test when category is not set: NORDVPN_{COUNTRY, PROTOCOL} are set, NORDVPN_CATEGORY is not set  |
| 3 | Test when api returns no result, send a warning with current parameters.  |
| 4 | Test when NORDVPN_SERVER is set, config file should be downloaded.

get list of servers and load:
`curl --silent https://api.nordvpn.com/server/stats | jq '. | to_entries|sort_by(.value.percent) | "\(.[].key): \(.[].value.percent)"'`

get load of a specific server:
`curl --silent https://api.nordvpn.com/server/stats/ca1509.nordvpn.com | jq '.percent'`

get list of available servers: `curl --silent https://api.nordvpn.com/server/stats | jq '. |to_entries | .[].key')`

### OVPN

The selection script parses the file names of the available on the official contrib repo (https://github.com/haugene/vpn-configs-contrib/tree/main/openvpn/ovpn).

OVPN utilizes ENV variables:

| Variable           | Function                                                                                                                                                            | Example                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `OVPN_PROTOCOL`  | Specifies either TCP or UDP selection                                                  | `OVPN_PROTOCOL=udp`          |
| `OVPN_COUNTRY` | Specifies the country to connect to. | `OVPN_COUNTRY=us` |
| `OVPN_CITY` | Specifies the city to connect to. | `OVPN_CITY=chicago` |
| `OVPN_CONNECTION` | Uses either standard or multihop VPN connections.  Currntly, OVPN only supports UDP. | `OVPN_CONNECTION=multihop`        |

As of August 29, 2022, the following options are available:
| Type          | Options                                                                                                                                                            | Example                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `multihop`  | toronto (ca), zurich (ch), chicago (us), new-york (us), any-city (se)         | `OVPN_COUNTRY=ca   OVPN_CITY=toronto`          |
| `standard` | vienna (at), sydney (au), toronto (ca) , zurich (ch), erfurt (de), frankfurt (de), offenbach (de), copenhagen (dk), madrid (es), helsinki (fl), paris (fr), london (gb), milan (it), tokyo (jp), oslo (no), warsaw (pl), bucharest (ro), gothenburg (se), malmo (se), stockholm (se), sundsvall (se), singapore (sg), kyiv (ua), atlanta (us), los-angeles (us), miami (us), new-york (us), any-city (de), any-city (se), any-city (us) | `OVPN_COUNTRY=us   OVPN_CITY=new-york` |


Review https://github.com/haugene/vpn-configs-contrib/tree/main/openvpn/ovpn for updates to country and city options.  


### MULLVAD & OVPN

According to [(#1355)](https://github.com/haugene/docker-transmission-openvpn/issues/1355)
ipv6 needs to be enabled for mullvad vpn
this is an example for docker compose
```yaml
# ipv6 must be enabled for Mullvad to work
        sysctls:
            - "net.ipv6.conf.all.disable_ipv6=0"
```
or add following line to docker run
```yaml
--sysctl net.ipv6.conf.all.disable_ipv6=0
```

The same is true for provider OVPN.

### NJAL.LA

[Njal.la](https://njal.la/vpn/) provides `.ovpn` configuration file. User
needs to specify to enable ipv6.

Here is a full example of `docker-compose.yml` file, assuming configuration file named `Njalla-VPN.ovpn`
is under local `config` subdirectory.

```yaml
version: '3.3'
services:
    transmission-openvpn:
      cap_add:
        - NET_ADMIN
      volumes:
        - ./config/Njalla-VPN.ovpn:/etc/openvpn/custom/default.ovpn:rw
        - ./data:/data:rw
      dns:
        - 1.1.1.1
      devices:
        - /dev/net/tun
      sysctls:
        # must enable ipv6 to have njal.la work
        - net.ipv6.conf.all.disable_ipv6=0
      environment:
        - OPENVPN_PROVIDER=CUSTOM
        - OPENVPN_USERNAME=user
        - OPENVPN_PASSWORD=pass
        - LOCAL_NETWORK=192.168.1.0/24
        - HEALTH_CHECK_HOST=google.com
      ports:
         - '9091:9091'
      logging:
        driver: json-file
        options:
          max-size: 10m
      image: haugene/transmission-openvpn:latest
```
