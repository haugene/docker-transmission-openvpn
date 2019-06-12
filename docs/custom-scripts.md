If you ever need to run custom code before or after transmission is executed or stopped, you can use the custom scripts feature.
Custom scripts are located in the /scripts directory which is empty by default.
To enable this feature, you'll need to mount the /scripts directory.

Once /scripts is mounted you'll need to write your custom code in the following bash shell scripts:

| Script                              | Function                                                     |
| ----------------------------------- | ------------------------------------------------------------ |
| /scripts/openvpn-pre-start.sh       | This shell script will be executed before openvpn start      |
| /scripts/transmission-pre-start.sh  | This shell script will be executed before transmission start |
| /scripts/transmission-post-start.sh | This shell script will be executed after transmission start  |
| /scripts/transmission-pre-stop.sh   | This shell script will be executed before transmission stop  |
| /scripts/transmission-post-stop.sh  | This shell script will be executed after transmission stop   |

Don't forget to include the #!/bin/bash shebang and to make the scripts executable using chmod a+x