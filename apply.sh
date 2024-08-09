#!/bin/bash

docker compose up -d &&
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