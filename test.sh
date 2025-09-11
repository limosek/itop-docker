#!/bin/sh

errexit(){
  echo $1
  exit $2
}

docker buildx build -t limosek/itop:321 --build-arg ITOP_VERSION=3.2.1 --build-arg ITOP_REVISION=16749 .
docker buildx build -t limosek/itop:322 .

docker stop it-itop 
docker stop it-mariadb
docker rm it-itop
docker rm it-mariadb
docker network rm itoptest
docker network create itoptest

docker run --rm -d \
  --network itoptest \
  --name it-mariadb \
  -e MARIADB_ROOT_PASSWORD=rootpass \
  -e MARIADB_DATABASE=itop \
  -e MARIADB_USER=itop \
  -e MARIADB_PASSWORD=itoppass \
  mariadb:latest

docker run --rm \
  --name it-itop \
  --network itoptest \
  -e TESTONLY=true \
  -e DBHOST=it-mariadb \
  -e DBNAME=itop \
  -e DBUSER=itop \
  -e DBPASSWORD=itoppass \
  -v ./data:/home/itop/data \
  -v ./conf:/home/itop/conf \
  -v ./prod:/home/itop/env-production \
  limosek/itop:321 2>&1 | tee instal.log | grep =====TEST_OK || errexit "Error" 1

docker run --rm \
  --name it-itop \
  --network itoptest \
  -e TESTONLY=true \
  -e DBHOST=it-mariadb \
  -e DBNAME=itop \
  -e DBUSER=itop \
  -e DBPASSWORD=itoppass \
  -v ./data:/home/itop/data \
  -v ./conf:/home/itop/conf \
  -v ./prod:/home/itop/env-production \
  limosek/itop:322 2>&1 | tee upgrade.log | grep =====TEST_OK || errexit "Error" 1
