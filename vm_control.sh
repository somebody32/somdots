#!/bin/bash

vu() {
  __get_vm_info

  if [ $? != 1 ];
  then
    prlctl start $__VM_NAME

    echo 'Mounting code folder...'
    until eval "sudo mount -o noowners,soft $__VM_HOST:/home/vagrant/$__VM_NAME ./code" > /dev/null 2>&1; do
      sleep 10
    done

    echo "Forwarding ports..."
    forward_ports_to_vm
  fi
}

vd() {
  __get_vm_info

  if [ $? != 1 ];
  then
    __unmount_code
    __down_ssh
    prlctl suspend $__VM_NAME
  fi
}

vh() {
  __get_vm_info

  if [ $? != 1 ];
  then
    __unmount_code
    __down_ssh
    prlctl stop $__VM_NAME
  fi
}

vs() {
  __get_vm_info

  if [ $? != 1 ];
  then
    `__ssh_to_vm`
  fi
}

forward_ports_to_vm() {
  __get_vm_info

  if [ -z "$1" ]
  then
    __up_tunnels $__VM_FW_PORTS
  else
    __up_tunnels "$@"
  fi
}

__unmount_code() {
  sudo umount -f ./code
}

__ssh_to_vm() {
  echo "ssh vagrant@$__VM_HOST"
}

__up_tunnels() {
  local tunnels
  tunnels=`echo "$@" | xargs -n1 -IPORT echo "ssh -o TCPKeepAlive=yes vagrant@$__VM_HOST -L "PORT":localhost:"PORT" -f -N"`

  for tunnel in ${tunnels};
  do
    eval $tunnel
  done
}

__down_ssh() {
  ps ux | grep "ssh .* vagrant@$__VM_HOST" | awk '{print $2}' | xargs kill > /dev/null 2>&1
}

__get_vm_info() {
  local CONFIG="./.vm_config"
  if [ ! -f $CONFIG ];
  then
    echo "No VM config file found, aborting"
    return 1
  else
    . ./.vm_config
  fi
}
