#!/usr/bin/env bash
set -euo pipefail

# # setup
. assert.sh
docker-compose down
for i in $(seq 1 3); do
  cp -f sentinel$i.conf .sentinel$i.conf
done
docker-compose up -d && sleep 20
echo

# variables
declare -A servers=(
  ['172.22.1.10']='redis1'
  ['172.22.1.20']='redis2'
  ['172.22.1.30']='redis3'
)

function set_vars () {
  MASTER_IP=$1
  MASTER_NAME=${servers[$MASTER_IP]}
  echo "Master: $MASTER_NAME at $MASTER_IP"

  SLAVE1_IP=
  SLAVE1_NAME=
  SLAVE2_IP=
  SLAVE2_NAME=

  for key in "${!servers[@]}"; do
    if [[ "$key" != "$MASTER_IP" ]]; then
      if [[ -z "$SLAVE1_IP" ]]; then
        SLAVE1_IP="$key"
        SLAVE1_NAME="${servers[$key]}"
        echo "Slave1: $SLAVE1_NAME at $SLAVE1_IP"
      else
        SLAVE2_IP="$key"
        SLAVE2_NAME="${servers[$key]}"
        echo "Slave2: $SLAVE2_NAME at $SLAVE2_IP"
      fi
    fi
  done
}

# test suite 1
set_vars $(docker exec -t sentinel_redis1_1 redis-cli -h 172.22.1.31 -p 26379 SENTINEL get-master-addr-by-name my_redis_master | cut -d\" -f2 | head -n1)
## cannot write to slave
assert "docker exec -t sentinel_${SLAVE1_NAME}_1 redis-cli set 'foo' 123" "(error) READONLY You can't write against a read only slave.\r"
## can write to master
assert "docker exec -t sentinel_${MASTER_NAME}_1 redis-cli set 'foo' 123" "OK\r"
## can read from slave what got written to master
assert "docker exec -t sentinel_${SLAVE2_NAME}_1 redis-cli get 'foo'" "\"123\"\r"

assert_end only write to master
echo

# test suite 2
## stop master
docker-compose stop $MASTER_NAME && sleep 20
echo

set_vars $(docker exec -t sentinel_${SLAVE2_NAME}_1 redis-cli -h 172.22.1.21 -p 26379 SENTINEL get-master-addr-by-name my_redis_master | cut -d\" -f2 | head -n1)

## can write to master
assert "docker exec -t sentinel_${MASTER_NAME}_1 redis-cli set 'foo' 345" "OK\r"
## can read what got written
assert "docker exec -t sentinel_${MASTER_NAME}_1 redis-cli get 'foo'" "\"345\"\r"
## can read what got written
assert "docker exec -t sentinel_${SLAVE2_NAME}_1 redis-cli get 'foo'" "\"345\"\r"

assert_end election works
