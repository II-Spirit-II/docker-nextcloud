#!/bin/bash
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /root/docker-nextcloud:/root/docker-nextcloud ubuntu_syncro:latest

