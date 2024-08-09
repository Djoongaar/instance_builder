#!/bin/bash

docker compose up -d &&

### BUILD AN INSTANCE BY TERRAFORM

docker exec instance_builder bash -c """
  cd infra &&
  terraform init &&
  terraform fmt &&
  terraform validate &&
  terraform apply -auto-approve &&
  chmod 400 .ssh/id_rsa &&
  cp .ssh/id_rsa* ~/.ssh/ &&
  rm -rf .ssh
  """

### SAVE INSTANCE DATA INTO INVENTORY

rm -f ansible/inventory.ini
echo "[myhosts]" >> ansible/inventory.ini
echo "$(docker exec instance_builder bash -c "cd infra && terraform output instance_public_ip")" >> ansible/inventory.ini

### INSTALLING OPENVPN and EASY-RSA

docker exec instance_builder bash -c "ansible-playbook -i ansible/inventory.ini ansible/openvpn.yml"
