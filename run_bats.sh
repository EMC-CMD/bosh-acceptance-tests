#!/usr/bin/env bash

set -e -x

source *.env.sh

check_param() {
  local name=$1
  local value=$(eval echo '$'$name)
  if [ "$value" == '' ]; then
    echo "environment variable $name must be set"
    exit 1
  fi
}

check_param stemcell_path
check_param bosh_director_public_ip
check_param bosh_director_private_ip
check_param private_key_path

check_param primary_network_cidr
check_param primary_network_gateway
check_param primary_network_range
check_param primary_network_manual_ip
check_param second_static_ip

cat > ${BAT_DEPLOYMENT_SPEC} <<EOF
---
cpi: onrack
properties:
  use_static_ip: true
  second_static_ip: ${second_static_ip}
  key_name:  bats
  pool_size: 1
  instances: 1
  uuid: $(bosh status --uuid)
  stemcell:
    name: bosh-openstack-kvm-ubuntu-trusty-go_agent-raw
    version: latest
  networks:
  - name: default
    static_ip: ${primary_network_manual_ip}
    type: manual
    cidr: ${primary_network_cidr}
    reserved: [${bosh_director_private_ip}]
    static: [${primary_network_range}]
    gateway: ${primary_network_gateway}
EOF

echo "using bosh CLI version..."
bosh version

echo "targeting bosh director at ${bosh_director_public_ip}"
bosh -n target ${bosh_director_public_ip}

./write_gemfile

bundle install

echo "run the tests"
bundle exec rspec spec
