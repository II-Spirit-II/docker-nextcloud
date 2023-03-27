# Nextcloud Docker Setup

This repository contains a docker-compose file and an nginx configuration file to set up Nextcloud with Docker.

## Prerequisites
- Docker installed
- Docker Compose installed

## Getting Started
1. Clone this repository.
2. Navigate to the repository directory.
3. Create a directory named "ssl" in the repository directory and add your SSL certificate and key to it.
4. Edit the docker-compose.yml file to customize your configuration.
5. Run the following command to start the containers:
`docker compose up -d`

## Configuration
The following services are defined in the docker-compose.yml file:

- **nextcloud**: Nextcloud server container with the following environment variables:
    - MYSQL_HOST: hostname of the MariaDB container
    - MYSQL_DATABASE: database name for Nextcloud
    - MYSQL_USER: database username for Nextcloud
    - MYSQL_PASSWORD: database password for Nextcloud
    - OVERWRITEPROTOCOL: set to "https" to enable HTTPS
    - Volumes:
      - /root/docker_compose/nextcloud:/var/www/html

- **mariadb**: MariaDB database container with the following environment variables:
    - MYSQL_ROOT_PASSWORD: root password for MariaDB
    - MYSQL_DATABASE: database name for Nextcloud
    - MYSQL_USER: database username for Nextcloud
    - MYSQL_PASSWORD: database password for Nextcloud
    - Volumes:
      - /root/docker_compose/mariadb:/var/lib/mysql

- **nginx**: Nginx reverse proxy container with the following features:
    - HTTPS configuration
    - SSL certificate and key configured via the ssl directory
    - Proxy pass to the Nextcloud container
    - Volumes:
      - /root/docker_compose/nginx.conf:/etc/nginx/nginx.conf

## Nginx Configuration
The nginx.conf file defines the Nginx configuration for the reverse proxy. It includes the following features:

- HTTP to HTTPS redirect
- HTTPS configuration with SSL certificate and key
- Proxy pass to the Nextcloud container
- Security headers

## Conclusion
This docker-compose file and nginx configuration can be used to quickly set up a Nextcloud server with HTTPS enabled.
