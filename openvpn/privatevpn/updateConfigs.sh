#!/bin/bash
set -e
shopt -s globstar

# Link might be updated, originally found on support page:
# https://privatevpn.com/support/getting-started/miscellaneous/openvpn/openvpn-configurations-files
PVPN_CONFIGS_URL="https://privatevpn.com/client/PrivateVPN-TUN.zip"

# From PrivateVPN support as of 4/11/2020
KNOWN_DEDICATED_IP_SERVERS_LIST=$(cat <<EOF
au-syd.pvdata.host
br-sao.pvdata.host
ca-tor.pvdata.host
ch-zur.pvdata.host
de-fra.pvdata.host
de-nur.pvdata.host
es-mad.pvdata.host
fi-esp.pvdata.host
fr-par.pvdata.host
in-che.pvdata.host
it-mil.pvdata.host
jp-tok.pvdata.host
nl-ams.pvdata.host
no-osl.pvdata.host
pl-tor.pvdata.host
se-got.pvdata.host
se-kis.pvdata.host
se-sto.pvdata.host
uk-lon.pvdata.host
us-buf.pvdata.host
us-los.pvdata.host
us-nyc4.pvdata.host
us-nyc.pvdata.host
193.180.119.2
EOF
)

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

# Make subdirectories for optional configs, where:
# tcp = tcp/443
# strong = AES-256-CBC cipher
# dedicateed = Dedicated IP address with all ports open
mkdir -p tcp \
	strong \
	tcp-strong \
	dedicated \
	dedicated-strong

# Download/unpack PrivateVPN configs
curl -sOJL "$PVPN_CONFIGS_URL"
unzip -qo -d extracted *.zip

# Copy original PrivateVPN configuration files
find ./extracted -name '*-TUN-1194.ovpn' -exec cp {} ./ \;
find ./extracted -name '*-TUN-443.ovpn' -exec cp {} ./tcp/ \;

# Cleanup original PrivateVPN configs
rm -f *.zip
rm -rf extracted

# Make config names more human-friendly
for file in **/*.ovpn; do
	directory=$(dirname "$file")
	filename=$(basename "$file")
	new_filename=$(sed \
		-e 's/-TUN-1194//' \
		-e 's/-TUN-443//' \
		-e 's/PrivateVPN-//'  \
		-e 's/-/\ /' \
		<<< "$filename"
	)
	mv "$file" "$directory/$new_filename"
done

# Unix line endings
sed -i 's/\r$//g' **/*.ovpn

# Remove unwanted OVPN options
sed -i "/tun-ipv6/d" **/*.ovpn

# Add wanted OVPN options
sed -i '/verb 3/a\
pull-filter ignore "DNS"\
pull-filter ignore "ping"\
ping 30\
ping-exit 120' **/*.ovpn

# Use creds text file
sed -i 's/^auth-user-pass.*$/auth-user-pass \/config\/openvpn-credentials\.txt/' **/*.ovpn

# Create "dedicated" variation
grep -Fl "${KNOWN_DEDICATED_IP_SERVERS_LIST}" *.ovpn \
	| xargs -d '\n' -I{} cp "{}" ./dedicated/ 

# Create "strong" variations
cp *.ovpn ./strong/
cp ./tcp/*.ovpn ./tcp-strong/
cp ./dedicated/*.ovpn ./dedicated-strong/
for file in ./*strong/*.ovpn; do
	sed -i 's/cipher\ AES-128-GCM/cipher\ AES-256-GCM/' "$file"
done

# Create links that omit the "1" in some connection names
# for convenience
for file in **/*1.ovpn; do
	pushd $(dirname "$file") &>/dev/null
	filename=$(basename "$file")
	destination=$(sed 's/\ 1//' <<< "$filename")
	ln -sf "$filename" "$destination"
	popd  &>/dev/null
done

# Links for backwards compatibility with previous PrivateVPN configs
ln -sf "UK London 2.ovpn" "london-uk.ovpn"
ln -sf "./dedicated/US Los Angeles.ovpn" "los-angeles-usa-allportfwd.ovpn"
ln -sf "US Los Angeles.ovpn" "los-angeles-usa.ovpn"
ln -sf "./dedicated/US New York 4.ovpn" "new-york-usa-allportfwd.ovpn"
ln -sf "./dedicated/SE Stockholm.ovpn" "stockholm-sweden-allportfwd.ovpn"
ln -sf "SE Stockholm.ovpn" "stockholm-sweden.ovpn"

# Create default link matching previous
ln -sf "SE Stockholm.ovpn" "default.ovpn"
