---
name: Bug report
about: Container is not behaving as expected, please make sure this is docker/transmission related and NOT provider related
title: ''
labels: 'bug'
assignees: ''

---

<!-- **PLEASE READ**

We expect you to look through the links provided in the checklist below
and investigate your issue before you submit a new one.
Please elaborate on what you tried before opening this issue.

**If you do not follow the template and show that you have done this, your issue will be closed automatically**
*Please preview your issue before posting to make sure the template is properly filled in*
-->

## Before creating this issue I have:
<!-- Put an X (no space) in the boxes to tick them, like this [X], check *Preview Issue* to make sure they are ticked -->
**REQUIRED**
- [ ] Read through the pinned issues for related problems
- [ ] Searched for similar [provider issues][pi] and [container issues][ci]
- [ ] [Read the documentation][rd], especially the troubleshooting section and FAQ
- [ ] Tried to add as much relevant information to the issue as possible
- [ ] Verified I have tried using newest release as well
- [ ] Agreed that my issue will be closed if I do not follow this template and will remain closed until I complete the template

[pi]: https://github.com/haugene/vpn-configs-contrib/issues
[ci]: https://github.com/haugene/docker-transmission-openvpn/issues
[rd]: https://haugene.github.io/docker-transmission-openvpn/


### Container version & last working release
<!-- Please post the version you are using -->
**Required, problem occurs in :** 
<!-- Release tag and/or build number --> 
```<placeholder>```


*If possible, last working version:* 
<!-- Release tag and/or build number --> 
```<Leave empty if not known>```

### Describe the problem
<!-- A clear and concise description of what the bug is. -->
<!-- Check your logs and compare it with the FAQ section of the documentation -->

**REQUIRED**
```txt
<placeholder>
```
### Describe the steps you have tried to solve the problem
<!-- A list of steps -->
<!--
 e.g 1) tried other release/build (which ones?)
     2) verified container can resolve DNS (added --dns?)
     3) check .ovpn is valid (outdated?)
     4) check settings.json is valid (try with clean container?)
     5) Checked issues #XXX and #XXX and tried XXX
     6) ...
 -->
<!-- (please paste into the code block) -->

**REQUIRED**
```txt
<-- Paste here -->
```

### Add your docker run command or docker-compose file or env details
<!-- To understand how your container is running, provide the docker run command or the docker-compose.yml file you used to start it. If you're using Portainer e.g. or other GUI, please export the config to text (Portainer > Inspect containter > Set to Text > Copy Config section) -->
<!-- (please paste into the code block) -->

**REQUIRED**
```txt
<-- Paste here -->
```

### Logs
<!-- Provide all logs from the container. By default the should not be any sensitive information there, but if there is then mask it with *** or something similar.
You can get the logs by running "docker logs <container-name> or download the logs from Portainer".
Make sure you include all the log-->
<!-- (please paste into the code block) -->
<!--This should start with
 e.g 
 Starting container with revision: 6ce64c4f367e509cbf018296e170cd08c0a93319
 Creating TUN device /dev/net/tun -->
 <!-- And end with as below (if not problem occurs earlier)
 e.g.
 Transmission startup script complete.
2021-02-19 08:41:43 /sbin/ip route add xx.xx.xx.xx/32 via 172.20.10.11
2021-02-19 08:41:43 /sbin/ip route add 0.0.0.0/1 via xx.xx.xx.xx
2021-02-19 08:41:43 /sbin/ip route add 128.0.0.0/1 via xx.xx.xx.xx
2021-02-19 08:41:43 Initialization Sequence Completed
-->

**REQUIRED**
```txt
<-- Paste here -->
```

### Host system
<!-- Are you running on Ubuntu, a NAS, Raspberry Pi, Mac OS or something else?
Which version of Docker are you using? -->
<!-- (please paste into the code block) -->

**REQUIRED**
```txt
<-- Paste here -->
```
<!-- check *Preview Issue* before submitting -->
