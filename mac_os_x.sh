#!/usr/bin/env bash
#
# This bootstraps Puppet on Mac OS X 10.8 and 10.7.
#
# Optional environmental variables:
#   - PUPPET_COLLECTION_URL: The URL to the Puppet package to install.
#
set -e

#--------------------------------------------------------------------
# Modifiable variables, please set them via environmental variables.
#--------------------------------------------------------------------
PUPPET_COLLECTION=${PUPPET_COLLECTION:-"pc1"}
case "${PUPPET_COLLECTION}" in
pc1) PUPPET_COLLECTION_URL=${PUPPET_COLLECTION_URL:-"https://downloads.puppet.com/mac/10.13/PC1/x86_64/puppet-agent-latest.dmg"} ;;
5|6|7)   PUPPET_COLLECTION_URL=${PUPPET_COLLECTION_URL:-"https://downloads.puppet.com/mac/puppet${PUPPET_COLLECTION}/10.15/x86_64/puppet-agent-latest.dmg"} ;;
*)
  echo "Unknown/Unsupported PUPPET_COLLECTION." >&2
  exit 1
esac

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT.
#--------------------------------------------------------------------
PATH=$PATH:/opt/puppetlabs/bin
if [ "${EUID}" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
elif which puppet > /dev/null 2>&1; then
  echo "Puppet $(puppet --version) is already installed."
  exit 0
fi

# This function will download a DMG from a URL, mount it, find
# the `pkg` in it, install that pkg, and unmount the package.
function install_dmg() {
  local name="$1"
  local url="$2"
  local dmg_path=$(mktemp -t "${name}-dmg")

  echo "Installing: ${name}"

  # Download the package into the temporary directory
  echo "-- Downloading DMG..."
  curl -L -o "${dmg_path}" "${url}" 2>/dev/null

  # Mount it
  echo "-- Mounting DMG..."
  local plist_path=$(mktemp -t puppet-bootstrap)
  hdiutil attach -plist "${dmg_path}" > "${plist_path}"
  mount_point=$(grep -E -o '/Volumes/[-.a-zA-Z0-9]+' "${plist_path}")

  # Install. It will be the only pkg in there, so just find any pkg
  echo "-- Installing pkg..."
  pkg_path=$(find "${mount_point}" -name '*.pkg' -mindepth 1 -maxdepth 1)
  installer -pkg "${pkg_path}" -target / >/dev/null

  # Unmount
  echo "-- Unmounting and ejecting DMG..."
  hdiutil eject "${mount_point}" >/dev/null
}

if [[ "${PUPPET_COLLECTION}" == "" ]]; then
  # Install Facter and Hiera and Puppet
  echo "Installing: facter from gem"
  gem install facter -v '~> 2.0' --no-ri --no-rdoc
  echo "Installing: hiera from gem"
  gem install hiera -v '~> 1.0' --no-ri --no-rdoc
  echo "Installing: puppet from gem"
  gem install puppet -v '~> 3.0' --no-ri --no-rdoc
  mkdir -p /var/lib/puppet /etc/puppet
  touch /etc/puppet/puppet.conf
else
  install_dmg "puppet-agent" "${PUPPET_COLLECTION_URL}"
fi

# Hide all users from the loginwindow with uid below 500, which will include the puppet user
defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool YES
