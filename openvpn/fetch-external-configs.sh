#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

source /etc/openvpn/utils.sh

VPN_CONFIG_SOURCE_TYPE="${VPN_CONFIG_SOURCE_TYPE:-github_zip}"

# Set default GitHub config repo
GITHUB_CONFIG_SOURCE_REPO="${GITHUB_CONFIG_SOURCE_REPO:-haugene/vpn-configs-contrib}"
GITHUB_CONFIG_SOURCE_REVISION="${GITHUB_CONFIG_SOURCE_REVISION:-main}"

if [[ "${VPN_CONFIG_SOURCE_TYPE}" == "github_zip" ]]; then

  function cleanup {
    echo "Cleanup: deleting ${config_repo_temp_zip_file} and ${config_repo_temp_dir}"
    rm -rf "${config_repo_temp_zip_file}" "${config_repo_temp_dir}"
  }

  config_repo_temp_zip_file=$(mktemp)
  config_repo_temp_dir=$(mktemp -d)
  trap cleanup EXIT

  # Concatenate URL for config bundle from the given GitHub repo
  GITHUB_CONFIG_BUNDLE_URL="https://github.com/${GITHUB_CONFIG_SOURCE_REPO}/archive/${GITHUB_CONFIG_SOURCE_REVISION}.zip"
  
  # Create a temporary file and download bundle to it
  echo "Downloading configs from ${GITHUB_CONFIG_BUNDLE_URL} into ${config_repo_temp_zip_file}"
  curl -sSL --fail -o "${config_repo_temp_zip_file}" "${GITHUB_CONFIG_BUNDLE_URL}"

  # Create a temporary folder and extract configs there
  echo "Extracting configs to ${config_repo_temp_dir}"
  unzip -q "${config_repo_temp_zip_file}" -d "${config_repo_temp_dir}"

  # Find the specified provider folder. Should be under <tmpDir>/<some-root-folder>/openvpn/<provider>
  provider_configs=$(find "${config_repo_temp_dir}"/*/openvpn -type d -name "${VPN_PROVIDER}")
  if [[ -z "${provider_configs}" ]]; then
    echo "ERROR: Could not find any configs for provider ${VPN_PROVIDER^^} in downloaded configs"
    exit 1
  fi

  # Replace current provider home folder with the downloaded directory
  echo "Found configs for ${VPN_PROVIDER^^} in ${provider_configs}, will replace current content in ${VPN_PROVIDER_HOME}"
  rm -rf "${VPN_PROVIDER_HOME}"
  mv "${provider_configs}" "${VPN_PROVIDER_HOME}"

  exit 0

elif [[ "${VPN_CONFIG_SOURCE_TYPE}" == "github_clone" ]]; then
  GITHUB_CONFIG_REPO_URL="https://github.com/${GITHUB_CONFIG_SOURCE_REPO}.git"
  config_repo=/tmp/config-repo

  echo "Will get configs from ${GITHUB_CONFIG_REPO_URL}"
  # Check if git repo exists and clone or pull based on that
  if [[ -d ${config_repo} ]]; then
    echo "Repository is already cloned, checking for update"
    cd ${config_repo}
    git pull
    git checkout "${GITHUB_CONFIG_SOURCE_REVISION}"
  else
    echo "Cloning ${GITHUB_CONFIG_REPO_URL} into ${config_repo}"
    git clone "${GITHUB_CONFIG_REPO_URL}" ${config_repo}
    cd ${config_repo}
    git checkout "${GITHUB_CONFIG_SOURCE_REVISION}"
  fi

  # Find the specified provider folder. Should be under <tmpDir>/<some-root-folder>/openvpn/<provider>
  provider_configs=$(find "${config_repo}"/openvpn -type d -name "${VPN_PROVIDER}")
  if [[ -z "${provider_configs}" ]]; then
    echo "ERROR: Could not find any configs for provider ${VPN_PROVIDER^^} in downloaded configs"
    exit 1
  fi

  # Replace current provider home folder with the one we've fetched
  echo "Found configs for ${VPN_PROVIDER^^} in ${provider_configs}, will replace current content in ${VPN_PROVIDER_HOME}"
  rm -r "${VPN_PROVIDER_HOME}"
  cp -r "${provider_configs}" "${VPN_PROVIDER_HOME}"

  exit 0

else
    "ERROR: VPN config source type ${VPN_CONFIG_SOURCE_TYPE} does not exist..."
    exit 1
fi
