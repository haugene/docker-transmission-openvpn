This is a list of providers that are bundled within the image. Feel free to create an issue if your provider is not on the list, but keep in mind that some providers generate config files per user. This means that your login credentials are part of the config an can therefore not be bundled. In this case you can use the custom provider setup described later in this readme. The custom provider setting can be used with any provider.

| Provider Name           | Config Value (`OPENVPN_PROVIDER`) |
| :---------------------- | :-------------------------------- |
| Anonine                 | `ANONINE`                         |
| AnonVPN                 | `ANONVPN`                         |
| BlackVPN                | `BLACKVPN`                        |
| BTGuard                 | `BTGUARD`                         |
| Cryptostorm             | `CRYPTOSTORM`                     |
| Cypherpunk              | `CYPHERPUNK`                      |
| elastictunnel.com       | `ELASTICTUNNEL`                   |
| ExpressVPN              | `EXPRESSVPN`                      |
| FastestVPN              | `FASTESTVPN`                      |
| FreeVPN                 | `FREEVPN`                         |
| FrootVPN                | `FROOT`                           |
| FrostVPN                | `FROSTVPN`                        |
| GhostPath               | `GHOSTPATH`                       |
| Giganews                | `GIGANEWS`                        |
| HideMe                  | `HIDEME`                          |
| HideMyAss               | `HIDEMYASS`                       |
| IntegrityVPN            | `INTEGRITYVPN`                    |
| IPredator               | `IPREDATOR`                       |
| IPVanish                | `IPVANISH`                        |
| IronSocket              | `IRONSOCKET`                      |
| Ivacy                   | `IVACY`                           |
| IVPN                    | `IVPN`                            |
| Mullvad                 | `MULLVAD`                         |
| NordVPN                 | `NORDVPN`                         |
| OctaneVPN               | `OCTANEVPN`                       |
| OVPN                    | `OVPN`                            |
| Perfect Privacy         | `PERFECTPRIVACY`                  |
| Private Internet Access | `PIA`                             |
| Privado                 | `PRIVADO`                         |
| PrivateVPN              | `PRIVATEVPN`                      |
| ProtonVPN               | `PROTONVPN`                       |
| proXPN                  | `PROXPN`                          |
| proxy.sh                | `PROXYSH `                        |
| PureVPN                 | `PUREVPN`                         |
| RA4W VPN                | `RA4W`                            |
| SaferVPN                | `SAFERVPN`                        |
| SlickVPN                | `SLICKVPN`                        |
| Smart DNS Proxy         | `SMARTDNSPROXY`                   |
| SmartVPN                | `SMARTVPN`                        |
| Surfshark               | `SURFSHARK`                       |
| TigerVPN                | `TIGER`                           |
| TorGuard                | `TORGUARD`                        |
| Trust.Zone              | `TRUSTZONE`                       |
| TunnelBear              | `TUNNELBEAR`                      |
| VPNArea.com             | `VPNAREA`                         |
| VPNBook.com             | `VPNBOOK`                         |
| VPNFacile               | `VPNFACILE`                       |
| VPNTunnel               | `VPNTUNNEL`                       |
| VPNUnlimited            | `VPNUNLIMITED`                    |
| VPN.AC                  | `VPNAC`                           |
| VPN.ht                  | `VPNHT`                           |
| VyprVpn                 | `VYPRVPN`                         |
| Windscribe              | `WINDSCRIBE`                      |
| ZoogVPN                 | `ZOOGVPN`                         |

## Adding new providers
If your VPN provider is not in the list of supported providers you could always create an issue on GitHub and see if someone could add it for you. But if you're feeling up for doing it yourself, here's a couple of pointers.

You clone this repository and create a new folder under "openvpn" where you put the .ovpn files your provider gives you. Depending on the structure of these files you need to make some adjustments. For example if they come with a ca.crt file that is referenced in the config you need to update this reference to the path it will have inside the container (which is /etc/openvpn/...). You also have to set where to look for your username/password.

There is a script called adjustConfigs.sh that could help you. After putting your .ovpn files in a folder, run that script with your folder name as parameter and it will try to do the changes described above. If you use it or not, reading it might give you some help in what you're looking to change in the .ovpn files.

Once you've finished modifying configs, you build the container and run it with OPENVPN_PROVIDER set to the name of the folder of configs you just created (it will be lowercased to match the folder names). And that should be it!

So, you've just added your own provider and you're feeling pretty good about it! Why don't you fork this repository, commit and push your changes and submit a pull request? Share your provider with the rest of us! :) Please submit your PR to the dev branch in that case.

### Using a custom provider

If you want to run the image with your own provider without building a new image, that is also possible. For some providers, like AirVPN, the .ovpn files are generated per user and contains credentials. They should not be added to a public image. This is what you do:

Add a new volume mount to your `docker run` command that mounts your config file:
`-v /path/to/your/config.ovpn:/etc/openvpn/custom/default.ovpn`

Then you can set `OPENVPN_PROVIDER=CUSTOM`and the container will use the config you provided.
NOTE: Your .ovpn config file probably contains a line that says `auth-user-pass`. This will prompt OpenVPN to ask for the
username and password. As this is running in a scripted environment that is not possible. Change it for `auth-user-pass /config/openvpn-credentials.txt`
which is the file where your `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` variables will be written to.

If you are using AirVPN or other provider with credentials in the config file, you still need
to set `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` as this is required by the startup script.
They will not be read by the .ovpn file, so you can set them to whatever.

Note that you still need to modify your .ovpn file as described in the previous section.
If you have an separate ca.crt, client.key or client.crt file in your volume mount should be a folder containing both the ca.crt and the .ovpn config.

Mount the folder contianing all the required files instead of the openvpn.ovpn file.
`-v /path/to/your/config/:/etc/openvpn/custom/`

Additionally the .ovpn config should include the full path on the docker container to the ca.crt and additional files. 
`ca /etc/openvpn/custom/ca.crt`

If `-e OPENVPN_CONFIG=` variable has been omitted from the `docker run` command the .ovpn config file must be named default.ovpn. 
If `-e OPENVPN_CONFIG=` is used with the custom provider the .ovpn config and variable must match as described above.
