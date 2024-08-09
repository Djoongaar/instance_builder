#!/bin/bash

docker compose up -d &&
docker exec instance_builder bash -c """
  cd infra &&
  terraform destroy -auto-approve
  """