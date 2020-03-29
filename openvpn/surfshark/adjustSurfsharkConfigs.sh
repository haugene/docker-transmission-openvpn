#Mass Rename All the Latest Config File Downloaded from https://account.surfshark.com/api/v1/server/configurations
rename 's/.prod.surfshark.com//' ./*.prod.surfshark.com*

#Remove The Following Three Lines Related to Ping from All Configs
for configFile in *.ovpn;
	do
		sed -i '/ping\ 15/d' "$configFile"
		sed -i '/ping-restart\ 0/d' "$configFile"
		sed -i '/ping-timer-rem/d' "$configFile"
	done