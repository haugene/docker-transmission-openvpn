## How we manage VPN providers

The container used to come bundled with a bunch of config files for a range of VPN providers.
This was fine when it was a handful or even a dozen supported providers, but as we approached
50 providers and 10k configs there wasn't time for anything else than keeping them up to date.

So we've tried to come up with a setup that is more maintainable. 
We have split the .ovpn configs out to a separate repository at:
[https://github.com/haugene/vpn-configs-contrib](https://github.com/haugene/vpn-configs-contrib).

All static configs that has to be manually updated will live there and be pulled on container startup.
We will try to set up a CODEOWNERS scheme and ask for more help from the community to keep them up to date.

Some providers are still provided from the core project and those are the one that have implemented
a script for fetching the configs dynamically. Going forward we will allow code in this project, not config.

So that is the story of how we now have two types of providers: `internal` and `external`.
The benefit of making a very native support for external configs is that it is much simpler for a user to
make a fork of the config repo and simply tell the container to use his or her fork. This way we can hopefully
empower many more to help out with keeping our providers up to date and add new ones.

## Out of the box supported providers

If you can't find your provider you are welcome to head over to the 
[config repo](https://github.com/haugene/vpn-configs-contrib) to request it or add it yourself.
Keep in mind that some providers generate configs per user where the authentication details are a part
of the config and they can therefore not be added here but has to be manually supplied by the user.
You can use any OpenVPN config with this container by mounting it as a file in the container.
For more info on that see the [using a custom provider](#using_a_custom_provider) section.

### Internal Providers

These providers are implemented as script in this project and will automatically
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
is the most up to date list of configs and providers that are supported. You can also use your own config repo
or extend/update the main repo by following the steps outlined in the [next section](#adding_or_updating_a_provider).


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

## Adding or updating a provider

TODO: Screenshots and examples of forking, adding and PR'ing

You clone this repository and create a new folder under "openvpn" where you put the .ovpn files your provider gives you. Depending on the structure of these files you need to make some adjustments. For example if they come with a ca.crt file that is referenced in the config you need to update this reference to the path it will have inside the container (which is /etc/openvpn/...). You also have to set where to look for your username/password.

There is a script called adjustConfigs.sh that could help you. After putting your .ovpn files in a folder, run that script with your folder name as parameter and it will try to do the changes described above. If you use it or not, reading it might give you some help in what you're looking to change in the .ovpn files.

Once you've finished modifying configs, you build the container and run it with OPENVPN_PROVIDER set to the name of the folder of configs you just created (it will be lowercased to match the folder names). And that should be it!

So, you've just added your own provider and you're feeling pretty good about it! Why don't you fork this repository, commit and push your changes and submit a pull request? Share your provider with the rest of us! :) Please submit your PR to the dev branch in that case.

## Using a custom provider
If you want to run the image with your own provider without building a new image, that is also possible. 

## Using a local single .ovpn file from provider
For some providers, like AirVPN, the .ovpn files are generated per user and contains credentials. 
They should not be added to a public image. This is what you do:

Add a new volume mount to your `docker run` command that mounts your config file:
`-v /path/to/your/config.ovpn:/etc/openvpn/custom/default.ovpn`

Then you can set `OPENVPN_PROVIDER=CUSTOM`and the container will use the config you provided.

NOTE: Your .ovpn config file probably contains a line that says `auth-user-pass`. This will prompt OpenVPN to ask for the
username and password. As this is running in a scripted environment that is not possible. Change it for `auth-user-pass /config/openvpn-credentials.txt`
which is the file where your `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` variables will be written to.

If you are using AirVPN or other provider with credentials in the config file, you still need
to set `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` as this is required by the startup script.
They will not be read by the .ovpn file, so you can set them to whatever.

If `-e OPENVPN_CONFIG=` variable has been omitted from the `docker run` command the .ovpn config file must be named default.ovpn.
If you have a separate ca.crt, client.key or client.crt file, then refer to the section below instead.


## Using a local set of .ovpn files from provider
If you do not want the build to download config from the provider but actually load you own config locally, please follow these steps

**Grab all files from your provider** (usually a .zip file to download & unzip)

**Copy them in a repository**, there should be .ovpn files and a ca.cert as well (example below /volume1/docker/transmission/ipvanish/)

**Mount the volume**
Compose sample:
```
             - /volume1/docker/transmission/ipvanish/:/etc/openvpn/custom/
```
**Declare the Custom provider, the target server and login/password**
Compose sample:
```
            - OPENVPN_PROVIDER=custom
            - OPENVPN_CONFIG=ipvanish-UK-Maidenhead-lhr-c02
            - OPENVPN_USERNAME=user
            - OPENVPN_PASSWORD=pass
```

**Open the .OVPN file, and modify**

_ca ca.ipvanish.com.crt_
into
```
ca /etc/openvpn/custom/ca.ipvanish.com.crt
```
_auth-user-pass_
into
```
auth-user-pass /config/openvpn-credentials.txt
```

_NOTE: the file openvpn-credentials.txt should contain 2 lines with your login and password, but actually it is ignored and it reverts nicely to OPENVPN_USERNAME and OPENVPN_PASSWORD variables ! See issue 1497. I don't even have this file on my filesystem any longer)_
