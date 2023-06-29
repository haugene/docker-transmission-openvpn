## How we manage VPN providers

The container used to come bundled with a bunch of config files for a range of VPN providers.
This was fine when it was a handful or even a dozen supported providers, but as we approached
50 providers and 10k configs there wasn't time for anything else than keeping them up to date.

So we've tried to come up with a more maintainable setup. 
We have split the .ovpn configs out to a separate repository at:
[https://github.com/haugene/vpn-configs-contrib](https://github.com/haugene/vpn-configs-contrib).

All static configs that have to be manually updated will live there and be pulled on container startup.
We will try to set up a CODEOWNERS scheme and ask for more help from the community to keep them up to date.

Some providers are still provided from the core project and those are the ones that have implemented
a script for fetching the configs dynamically. Going forward we will allow code in this project, not config.

So that is the story of how we now have two types of providers: `internal` and `external`.
The benefit of having native support for external configs is that it is much simpler for a user to
make a fork of the config repo and simply tell the container to use his or her fork. This way we can hopefully
empower many more to help out with keeping our providers up to date and adding new ones.

## Out-of-the-box supported providers

If you can't find your provider you are welcome to head over to the 
[config repo](https://github.com/haugene/vpn-configs-contrib) to request it or add it yourself.
Keep in mind that some providers generate configs per user where the authentication details are a part
of the config and they can therefore not be added here but has to be manually supplied by the user.
You can use any OpenVPN config with this container by mounting it as a file in the container.
For more info on that see the [using a custom provider](#using_a_custom_provider) section.

### Internal Providers

These providers are implemented as a script in this project and will automatically
download new configs directly from the provider on container startup.

| Provider Name             | Config Value (`OPENVPN_PROVIDER`) |
| :------------------------ | :-------------------------------- |
| IPVanish                  | `IPVANISH`                        |
| NordVPN                   | `NORDVPN`                         |
| Private Internet Access   | `PIA`                             |
| VyprVpn                   | `VYPRVPN`                         |

### External Providers

These providers are fetched from our [config repo](https://github.com/haugene/vpn-configs-contrib) on startup.
They have to be manually updated in that repo when the provider changes them but we're trying to keep them up to date.

Note that we try to keep this list in sync but it is the files and folders in the config repo that ultimately
is the most up-to-date list of configs and providers that are supported.


| Provider Name             | Config Value (`OPENVPN_PROVIDER`) |
| :------------------------ | :-------------------------------- |
| Anonine                   | `ANONINE`                         |
| AnonVPN                   | `ANONVPN`                         |
| BlackVPN                  | `BLACKVPN`                        |
| BTGuard                   | `BTGUARD`                         |
| Cryptostorm               | `CRYPTOSTORM`                     |
| ExpressVPN                | `EXPRESSVPN`                      |
| FastestVPN                | `FASTESTVPN`                      |
| FreeVPN                   | `FREEVPN`                         |
| FrootVPN                  | `FROOT`                           |
| FrostVPN                  | `FROSTVPN`                        |
| Getflix                   | `GETFLIX`                         |
| GhostPath                 | `GHOSTPATH`                       |
| Giganews                  | `GIGANEWS`                        |
| HideMe                    | `HIDEME`                          |
| HideMyAss                 | `HIDEMYASS`                       |
| IntegrityVPN              | `INTEGRITYVPN`                    |
| IronSocket                | `IRONSOCKET`                      |
| Ivacy                     | `IVACY`                           |
| IVPN                      | `IVPN`                            |
| Mullvad                   | `MULLVAD`                         |
| OctaneVPN                 | `OCTANEVPN`                       |
| OVPN                      | `OVPN`                            |
| Privado                   | `PRIVADO`                         |
| PrivateVPN                | `PRIVATEVPN`                      |
| ProtonVPN                 | `PROTONVPN`                       |
| proXPN                    | `PROXPN`                          |
| PureVPN                   | `PUREVPN`                         |
| RA4W VPN                  | `RA4W`                            |
| SaferVPN                  | `SAFERVPN`                        |
| SlickVPN                  | `SLICKVPN`                        |
| SlickVPNCore              | `SLICKVPNCORE`                    |
| Smart DNS Proxy           | `SMARTDNSPROXY`                   |
| SmartVPN                  | `SMARTVPN`                        |
| Surfshark                 | `SURFSHARK`                       |
| TigerVPN                  | `TIGER`                           |
| TorGuard                  | `TORGUARD`                        |
| Trust.Zone                | `TRUSTZONE`                       |
| TunnelBear                | `TUNNELBEAR`                      |
| VPN.AC                    | `VPNAC`                           |
| VPNArea.com               | `VPNAREA`                         |
| VPNBook.com               | `VPNBOOK`                         |
| VPNFacile                 | `VPNFACILE`                       |
| VPN.ht                    | `VPNHT`                           |
| VPNTunnel                 | `VPNTUNNEL`                       |
| VPNUnlimited              | `VPNUNLIMITED`                    |
| Windscribe                | `WINDSCRIBE`                      |
| ZoogVPN                   | `ZOOGVPN`                         |

## Use your own config without building the image

If you have a .ovpn file from your VPN provider and you want to use it but you either don't
know how to build the image yourself or if you don't want to there is another way.

Check out the [guide for this](https://github.com/haugene/vpn-configs-contrib/blob/main/CONTRIBUTING.md)
in the config repo.

## Using a local single .ovpn file from a provider
For some providers, like AirVPN, the .ovpn files are generated per user and contain credentials. 
These files can not be hosted anywhere publicly visible. Then you can mount the files into the container
and use them directly from your local host.

**Grab all files from your provider** (usually a .zip file to download & unzip)

**Copy them into a folder on your Docker host**, there might be .ovpn files and ca.cert as well (example below /volume1/docker/ipvanish/)

**Mount the volume**
Compose sample:
```
             - /volume1/docker/ipvanish/:/etc/openvpn/custom/
```
**Declare the Custom provider, the target server and login/password**
Also important to note here is that `OPENVPN_CONFIG` value needs to be the name of the ovpn file wanting to be referenced in the `/etc/openvpn/custom` volume. In the example below the ovpn file name is `ipvanish-UK-Maidenhead-lhr-c02.ovpn` 

Compose sample:
```
            - OPENVPN_PROVIDER=custom
            - OPENVPN_CONFIG=ipvanish-UK-Maidenhead-lhr-c02
            - OPENVPN_USERNAME=user
            - OPENVPN_PASSWORD=pass
```
Docker ENV vars sample: 
```
              -e OPENVPN_PROVIDER=custom \
              -e OPENVPN_CONFIG=ipvanish-UK-Maidenhead-lhr-c02 \
              -e OPENVPN_USERNAME=user \
              -e OPENVPN_PASSWORD=pass \
```

### Do not mount single config file

Do not mount a single config directly. The container will fail if you try, since it causes sed errors when modify-openvpn-config.sh is executed.
Instead mount the directory where the config exists.

```bash
sed: cannot rename /etc/openvpn/custom/sedHeF3gS: Device or resource busy
```

