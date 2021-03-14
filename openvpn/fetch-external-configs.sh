#! /bin/bash

set -o nounset
set -o errexit
set -o pipefail

VPN_CONFIG_SOURCE_TYPE="${VPN_CONFIG_SOURCE_TYPE:-github_zip}"

# Set default GitHub config repo
GITHUB_CONFIG_SOURCE_REPO="${GITHUB_CONFIG_SOURCE_REPO:-haugene/vpn-configs-contrib}"
GITHUB_CONFIG_SOURCE_REVISION="${GITHUB_CONFIG_SOURCE_REVISION:-main}"

if [[ "${VPN_CONFIG_SOURCE_TYPE}" == "github_zip" ]]; then

  function cleanup {
    echo "Cleanup: deleting ${config_repo_temp_zip_file} and ${config_repo_temp_dir}"
    rm -rf "${config_repo_temp_zip_file}" "${config_repo_temp_dir}"
  }
  trap cleanup EXIT

  # Concatenate URL for config bundle from the given GitHub repo
  GITHUB_CONFIG_BUNDLE_URL="https://github.com/${GITHUB_CONFIG_SOURCE_REPO}/archive/${GITHUB_CONFIG_SOURCE_REVISION}.zip"
  
  # Create a temporary file and download bundle to it
  config_repo_temp_zip_file=$(mktemp)
  echo "Downloading configs from ${GITHUB_CONFIG_BUNDLE_URL} into ${config_repo_temp_zip_file}"
  curl -sSL -o "${config_repo_temp_zip_file}" "${GITHUB_CONFIG_BUNDLE_URL}"

  # Create a temporary folder and extract configs there
  config_repo_temp_dir=$(mktemp -d)
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
  rm -r "${VPN_PROVIDER_HOME}"
  mv "${provider_configs}" "${VPN_PROVIDER_HOME}"

  exit 0

else
    "ERROR: VPN config source type ${VPN_CONFIG_SOURCE_TYPE} does not exist..."
    exit 1
fi
