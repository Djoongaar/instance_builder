#!/bin/bash

### BUILD AN INSTANCE BY TERRAFORM

check_server_state() {
  local counter=0
  local max_try=100

  echo -n "Checking instance: "

  while true
    do
      if
        [[ $(docker run --rm ghcr.io/djoongaar/terraform bash -c "aws ec2 describe-instance-status --instance-ids $1 | jq -r '.InstanceStatuses[0].InstanceState.Name'") == "running" ]] &&
        [[ $(docker run --rm ghcr.io/djoongaar/terraform bash -c "aws ec2 describe-instance-status --instance-ids $1 | jq -r '.InstanceStatuses[0].InstanceStatus.Status'") == "ok" ]] &&
        [[ $(docker run --rm ghcr.io/djoongaar/terraform bash -c "aws ec2 describe-instance-status --instance-ids $1 | jq -r '.InstanceStatuses[0].SystemStatus.Status'") == "ok" ]]; then
          break
      else
        if [ "$counter" -gt "$max_try" ]; then
          echo "[FAILED]"
          exit 1
        fi
        counter=$((counter+1))
        echo -n "."
        sleep 5
      fi
    done
  echo "[OK]"
}

create_server() {
  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c """
      cd vpn &&
      terraform init &&
      terraform fmt &&
      terraform validate &&
      terraform apply -auto-approve &&
      chmod 400 .ssh/id_rsa
    """

  # Saving instance configuration into json file
  rm -f vpn/instance.json &&
  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c """
      cd vpn &&
      terraform output -json
    """ > vpn/instance.json

  # Exporting variables
  export INSTANCE_PUBLIC_IP=$(cat vpn/instance.json | jq -r '.instance_public_ip.value')
  export INSTANCE_ID=$(cat vpn/instance.json | jq -r '.instance_id.value')

  # Creating inventory
  rm -f vpn/inventory.ini &&
  echo "[myhosts]" >> vpn/inventory.ini
  echo  "$INSTANCE_PUBLIC_IP" >> vpn/inventory.ini
}

install_openvpn() {
  check_server_state "$INSTANCE_ID"

  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c "ansible-playbook -v -i vpn/inventory.ini vpn/openvpn.yml"
}

get_admin_configuration() {
  export INSTANCE_PUBLIC_IP=$(cat vpn/instance.json | jq -r '.instance_public_ip.value')

  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c "scp -i vpn/.ssh/id_rsa $INSTANCE_PUBLIC_IP:~/client-configs/files/admin.ovpn vpn/aws.ovpn"
}

create_server
install_openvpn
get_admin_configuration