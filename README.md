# Redis Sentinel Docker Example

This repo is a demo of a simple Redis high availability setup on Docker,
with a few tests.

## Prerequisites

* docker
* docker-compose
* /bin/bash

## Usage

1. Read [docker-compose.yml](./docker-compose.yml)
1. Read [sentinel.conf](./sentinel.conf)
1. Read [test.sh](./test.sh)
1. Run the tests: `./test.sh`:

    ```
    Master: 172.22.1.10
    all 3 only write to master tests passed in 25.000s.
    Stopping sentinel_redis1_1 ... done
    New master: 172.22.1.20
    all 3 election works tests passed in 17.000s.
    ```
