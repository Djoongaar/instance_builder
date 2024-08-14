#!/bin/bash

destroy_vpn_server() {
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

destroy_vpn_server
