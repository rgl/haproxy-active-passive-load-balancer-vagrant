#!/bin/bash
set -eux

extra_hosts="$1"; shift || true

# set the extra hosts.
cat >>/etc/hosts <<EOF
$extra_hosts
EOF
