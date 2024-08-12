#!/bin/bash

docker compose up -d &&
docker exec instance_builder bash -c """
  cd vpn &&
  terraform destroy -auto-approve
  """

rm -f vpn/inventory.ini
