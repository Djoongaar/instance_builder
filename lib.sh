#!/bin/bash

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

_create_server() {
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

  # Creating inventory
  rm -f vpn/inventory.ini &&
  echo "[myhosts]" >> vpn/inventory.ini
  echo  "$INSTANCE_PUBLIC_IP" >> vpn/inventory.ini
}

_install_openvpn() {
  check_server_state "$INSTANCE_ID"

  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c "ansible-playbook -v -i vpn/inventory.ini vpn/openvpn.yml"
}

_get_admin_configuration() {
  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c "scp -i vpn/.ssh/id_rsa $INSTANCE_PUBLIC_IP:~/client-configs/files/admin.ovpn vpn/aws.ovpn"
}

_destroy_server() {
  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c """
      cd vpn &&
      terraform destroy -auto-approve
    """

  rm -f vpn/instance.json
  rm -f vpn/inventory.ini
  rm -rf vpn/.ssh
}

_add_client() {
  local client_name="$1"

  check_server_state "$INSTANCE_ID"
  echo $client_name

  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    ghcr.io/djoongaar/terraform \
    bash -c "ansible-playbook -v -i vpn/inventory.ini vpn/add_client.yml -e \"new_client=$client_name\""

  docker run \
    --rm \
    --volume "./vpn:/code/vpn" \
    --env-file .env \
    ghcr.io/djoongaar/terraform \
    bash -c "scp -i vpn/.ssh/id_rsa $INSTANCE_PUBLIC_IP:~/client-configs/files/$client_name.ovpn vpn/$client_name.ovpn"
}