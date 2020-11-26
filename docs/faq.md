
* [The container runs, but I can't access the web ui](#the_container_runs_but_i_cant_access_the_web_ui)
* [RTNETLINK answers: File exists](#rtnetlink_answers_file_exists)
* [TUNSETIFF tun: Operation not permitted](#tunsetiff_tun_operation_not_permitted)
* [AUTH: Received control message: AUTH_FAILED](#auth_received_control_message_auth_failed)

## The container runs, but I can't access the web ui

[TODO](https://github.com/haugene/docker-transmission-openvpn/issues/1558): Short explanation and link to [networking](vpn-networking.md)

## RTNETLINK answers: File exists

[TODO](https://github.com/haugene/docker-transmission-openvpn/issues/1558): Conflicting LOCAL_NETWORK values. Short explanation and link to [networking](vpn-networking.md)


## TUNSETIFF tun: Operation not permitted

[TODO](https://github.com/haugene/docker-transmission-openvpn/issues/1558): Permissions issue. Is NET_ADMIN given? Does it work with --privileged? Some platforms has it harder than others.

## AUTH: Received control message: AUTH_FAILED

If your logs end like this, the wrong username/password was sent to your VPN provider:
```
AUTH: Received control message: AUTH_FAILED
SIGTERM[soft,auth-failure] received, process exiting
```

[TODO](https://github.com/haugene/docker-transmission-openvpn/issues/1558): Special chars in password? Separate credentials for OpenVPN? Check file content of /config/openvpn-credentials.txt and contact provider