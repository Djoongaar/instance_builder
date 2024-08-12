#!/bin/bash

docker compose up -d &&

### BUILD AN INSTANCE BY TERRAFORM

docker exec instance_builder bash -c """
  cd vpn &&
  terraform init &&
  terraform fmt &&
  terraform validate &&
  terraform apply -auto-approve &&
  chmod 400 .ssh/id_rsa &&
  cp .ssh/id_rsa* ~/.ssh/ &&
  rm -rf .ssh
  """

### SAVE INSTANCE DATA INTO INVENTORY

rm -f vpn/inventory.ini
echo "[myhosts]" >> vpn/inventory.ini
echo "$(docker exec instance_builder bash -c "cd vpn && terraform output instance_public_ip")" >> vpn/inventory.ini
