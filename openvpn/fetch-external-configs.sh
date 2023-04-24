#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

source /etc/openvpn/utils.sh

# Set default GitHub config repo
GITHUB_CONFIG_SOURCE_REPO="${GITHUB_CONFIG_SOURCE_REPO:-haugene/vpn-configs-contrib}"
GITHUB_CONFIG_SOURCE_REVISION="${GITHUB_CONFIG_SOURCE_REVISION:-main}"
GITHUB_CONFIG_REPO_URL="https://github.com/${GITHUB_CONFIG_SOURCE_REPO}.git"
config_repo=/config/vpn-configs-contrib

# Add safe directory for repo folder
git config --global --add safe.directory "${config_repo}"

echo "Will get configs from ${GITHUB_CONFIG_REPO_URL}"
# Check if git repo exists and clone or pull based on that
if [[ -d ${config_repo} ]]; then
  GITHUB_CONFIG_SOURCE_LOCAL=$(git -C "${config_repo}" remote -v | head -1 | awk '{print $2}' | sed -e 's/https:\/\/github.com\///' -e 's/.git//')
  if [ "$GITHUB_CONFIG_SOURCE_LOCAL" == "$GITHUB_CONFIG_SOURCE_REPO" ]; then
    echo "Repository is already cloned, checking for update"
    git -C "${config_repo}" pull
    git -C "${config_repo}" checkout "${GITHUB_CONFIG_SOURCE_REVISION}"
  else
    echo "Cloning ${GITHUB_CONFIG_REPO_URL} into ${config_repo}"
    config_repo_old="${config_repo}" + "_old"
    mv "${config_repo}" "${config_repo_old}"
    git clone -b "${GITHUB_CONFIG_SOURCE_REVISION}" "${GITHUB_CONFIG_REPO_URL}" "${config_repo}"
else
  echo "Cloning ${GITHUB_CONFIG_REPO_URL} into ${config_repo}"
  git clone -b "${GITHUB_CONFIG_SOURCE_REVISION}" "${GITHUB_CONFIG_REPO_URL}" "${config_repo}"
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
