#!/bin/bash
cloudflared --origincert /data/cloudflared/cert.pem --config /data/cloudflared/config.yml tunnel run transmission
