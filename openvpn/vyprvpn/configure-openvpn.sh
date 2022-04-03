#!/bin/bash
# https://support.vyprvpn.com/hc/en-us/articles/360038096131-Where-can-I-find-the-OpenVPN-files-

source /etc/openvpn/utils.sh

if [[ -z "$VPN_PROVIDER_HOME" ]]; then
  echo "ERROR: Need to have VPN_PROVIDER_HOME set to call this script" && exit 1
fi

# Download & extract ovpn files from provider
baseURL="https://support.vyprvpn.com/hc/article_attachments/360052617332"
vyprvpn_config_bundle="Vypr_OpenVPN_20200320.zip"
tmp_file=$(mktemp)
tmp_dir=$(mktemp -d)

download_extract () {
  echo "Downloading OpenVPN configs into temporary file ${tmp_file}"
  curl -sSL "${baseURL}/${vyprvpn_config_bundle}" -o "${tmp_file}"

  # Delete all files for VyprVPN provider, except scripts
  find "${VPN_PROVIDER_HOME}" -type f ! -iname "*.sh" -delete

  echo "Temporarily extracting OpenVPN configs into directory ${tmp_dir}"
  unzip -qq "${tmp_file}" -d "${tmp_dir}"
}

rename_configs () {
  # Automatically renames & moves the OVPN files with the encryption keysize as part of their names
  for ks in $(find "${tmp_dir}"/GF_OpenVPN_20200320/* -maxdepth 1 -type d -print | awk -F'/' '{print $NF}' | tr -d '[:alpha:][:punct:]'); do
    for f in "${tmp_dir}/GF_OpenVPN_20200320/OpenVPN${ks}"/*.ovpn; do
      base=$(echo "${f}" | awk -F'/' '{print $NF}'|  awk -F'.' '{print $1}')
      ext=$(echo "${f}" | awk -F'/' '{print $NF}' | awk -F'.' '{print $2}')
      nf=$(echo "${base}-${ks}.${ext}")
      sed -i '/keepalive.*/d' "${f}"
      cp "${f}" "${VPN_PROVIDER_HOME}/${nf}"
    done
  done
  cp "${tmp_dir}"/GF_OpenVPN_20200320/OpenVPN256/ca.vyprvpn.com.crt "${VPN_PROVIDER_HOME}"

  # Select a random server as default.ovpn
  ln -sf "$(find "${VPN_PROVIDER_HOME}" -iname "*.ovpn" | shuf -n 1)" "${VPN_PROVIDER_HOME}/default.ovpn"
}

# Only download configs if /etc/openvpn/vyprvpn is empty
if find "${VPN_PROVIDER_HOME}" -type f ! -iname 'configure-openvpn.sh' | grep -q 'ovpn'; then
  echo "ovpn files detected, not downloading configs"
else
  download_extract
  rename_configs
  echo "Removing ${tmp_dir} & ${tmp_file}"
  rm -rf "${tmp_dir}"
  rm -f "${tmp_file}"
fi
