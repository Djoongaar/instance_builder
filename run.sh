#!/bin/bash

source lib.sh

### Exporting variables
export INSTANCE_PUBLIC_IP=$(cat vpn/instance.json | jq -r '.instance_public_ip.value')
export INSTANCE_ID=$(cat vpn/instance.json | jq -r '.instance_id.value')

if [ "$1" = "--create" ]; then
  ### Build an instance by terraform
	_create_server
	### Install and configure OpenVPN Server, PKI
  _install_openvpn
  ### Create admin configuration
  _get_admin_configuration
elif [ "$1" = "--destroy" ]; then
  _destroy_server
elif [ "$1" = "--add-client" ]; then
  if [ -z $2 ]; then
    echo "You should provide client name"
  else
    # TODO: Вот тут нужно доабвить валидацию имени:
    # TODO: Имя должно состоять только из буквенно-цифровых симоволов
    # TODO: Имя должно быть не короче 3-х символов
    # TODO: Приводить имя клиента к нижнему регистру
    # TODO: Имя должно быть уникально
    _add_client "$2"
  fi
fi

