#!/bin/bash
. assert.sh

docker-compose down

cat sentinel.conf > .sentinel1.conf
cat sentinel.conf > .sentinel2.conf
cat sentinel.conf > .sentinel3.conf

docker-compose up -d && sleep 15
# test suite 1
MASTER=$(docker exec -t sentinel_redis2_1 redis-cli -h 172.22.1.21 -p 26379 SENTINEL get-master-addr-by-name my_redis_master | cut -d\" -f2 | head -n1)
echo "Master: $MASTER"

## cannot write to slave
assert "docker exec -t sentinel_redis2_1 redis-cli set 'foo' 123" "(error) READONLY You can't write against a read only slave.\r"
## can write to master
assert "docker exec -t sentinel_redis1_1 redis-cli set 'foo' 123" "OK\r"
## can read from slave what got written to master
assert "docker exec -t sentinel_redis3_1 redis-cli get 'foo'" "\"123\"\r"

assert_end only write to master

# test suite 2
## stop master
docker-compose stop redis1 && sleep 15

MASTER=$(docker exec -t sentinel_redis2_1 redis-cli -h 172.22.1.21 -p 26379 SENTINEL get-master-addr-by-name my_redis_master | cut -d\" -f2 | head -n1)
echo "New master: $MASTER"

## can write to master
assert "docker exec -t sentinel_redis2_1 redis-cli -h $MASTER -p 6379 set 'foo' 345" "OK\r"
## can read what got written
assert "docker exec -t sentinel_redis2_1 redis-cli get 'foo'" "\"345\"\r"
## can read what got written
assert "docker exec -t sentinel_redis3_1 redis-cli get 'foo'" "\"345\"\r"

assert_end election works
