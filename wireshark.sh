#!/bin/bash
set -euxo pipefail

vm_name=${1:-lb}; shift || true
interface_name=${1:-eth1}; shift || true
capture_filter=${1:-not port 22}; shift || true

mkdir -p shared
vagrant ssh-config $vm_name >shared/$vm_name-ssh-config.conf
wireshark -o "gui.window_title:$vm_name $interface_name" -k -i <(ssh -F shared/$vm_name-ssh-config.conf $vm_name "sudo tcpdump -s 0 -U -n -i $interface_name -w - $capture_filter")
