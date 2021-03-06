#!/usr/bin/env bash
# Bootstrap Puppet on CentOS 5.x
# Tested on CentOS 5.11 64bit

set -e

# if PUPPET_COLLECTION is not prepended with a dash "-", add it
[[ "${PUPPET_COLLECTION}" == "" ]] || [[ "${PUPPET_COLLECTION:0:1}" == "-" ]] || \
  PUPPET_COLLECTION="-${PUPPET_COLLECTION}"
[[ "${PUPPET_COLLECTION}" == "" ]] && PINST="puppet" || PINST="puppet-agent"

PUPPETLABS_RELEASE_RPM="https://uitlpupp02.mcs.miamioh.edu/puppet-bootstrap/puppetlabs-release${PUPPET_COLLECTION}-el-5.noarch.rpm"
PUPPET_PACKAGE=${PUPPET_PACKAGE:-$PINST}

PATH=$PATH:/opt/puppetlabs/bin
if [ "${EUID}" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
elif rpm --quiet -q ${PUPPET_PACKAGE}; then
  echo "Puppet $(puppet --version) is already installed."
  exit 0
fi

# Install Puppet Labs repo
echo "Configuring PuppetLabs repo..."
repo_path=$(mktemp)
curl -L -o "${repo_path}" "${PUPPETLABS_RELEASE_RPM}" 2>/dev/null
rpm --quiet -i "${repo_path}" || true
rm "${repo_path}"

# Install Puppet
echo "Installing Puppet..."
yum install -q -y ${PUPPET_PACKAGE}

echo "Puppet installed!"
