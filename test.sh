#!/bin/sh

errexit(){
  echo $1
  exit $2
}

run_mariadb(){
  docker run --rm -d \
    --network itoptest \
    --name it-mariadb \
    -e MARIADB_ROOT_PASSWORD=rootpass \
    -e MARIADB_DATABASE=itop \
    -e MARIADB_USER=itop \
    -e MARIADB_PASSWORD=itoppass \
    mariadb:10
}

cleanup(){
  docker stop it-itop 
  docker stop it-mariadb
  docker rm it-itop
  docker rm it-mariadb
  docker network rm itoptest
  docker network create itoptest
}

cleanup

docker buildx build -t limosek/itop:321 --build-arg ITOP_VERSION=3.2.1 --build-arg ITOP_REVISION=16749 .
docker buildx build -t limosek/itop:322 .

run_mariadb

echo "Testing clean installation of 3.2.1"
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
  limosek/itop:321 2>&1 | tee install.log | grep =====TEST_OK || errexit "Error" 1

echo "Testing upgrade to 3.2.2"
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

docker stop it-mariadb
docker rm it-mariadb

run_mariadb
  
echo "Testing clean installation of 3.2.2"
docker run --rm \
  --name it-itop \
  --network itoptest \
  -e TESTONLY=true \
  -e DBHOST=it-mariadb \
  -e DBNAME=itop \
  -e DBUSER=itop \
  -e DBPASSWORD=itoppass \
  limosek/itop:322 2>&1 | tee install2.log | grep =====TEST_OK || errexit "Error" 1

echo "Testing reinstallation of 3.2.2"
docker run --rm \
  --name it-itop \
  --network itoptest \
  -e TESTONLY=true \
  -e DBHOST=it-mariadb \
  -e DBNAME=itop \
  -e DBUSER=itop \
  -e DBPASSWORD=itoppass \
  limosek/itop:322 2>&1 | tee install3.log | grep =====TEST_OK || errexit "Error" 1

cleanup

echo "All tests passed!"
