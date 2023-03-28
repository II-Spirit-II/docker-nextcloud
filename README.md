# Nextcloud Docker Setup

This repository contains a docker-compose file and an nginx configuration file to set up Nextcloud with Docker.

## Prerequisites
- Docker installed
- Docker Compose installed

## Getting Started
1. Clone this repository: `git clone https://github.com/II-Spirit-II/docker-nextcloud.git` and put it in `/root/` (this is very important because the volumes in `docker-compose.yml` are set in this directory for now
2. Navigate to the repository directory: `cd /root/docker-nextcloud`
3. Create a directory named "ssl" (it's very important to respect this name) in the repository directory and add your SSL certificate and key to it:

```
cd /path/to/git
mkdir ssl
```

Here are the commands to create a self-signed SSL certificate using OpenSSL:
- Create a private key:

```openssl genrsa -out server.key 2048```

- Create a Certificate Signing Request (CSR):

```openssl req -new -key server.key -out server.csr```

- Self-sign the certificate using the private key and CSR:

```openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt```

Note that these self-signed certificates are not considered secure for production use and are intended for testing or development purposes only. For production use, it is recommended to purchase an SSL certificate from a trusted certification authority.

4. Edit the docker-compose.yml file to customize your configuration.
5. Run the following command to start the containers: `docker compose up -d`

## Recommendations:

Normally, once `server.crt` and `server.key` are created in your directory named SSL, everything should work when launching with `docker compose up -d`. However, it is strongly recommended to modify the database environment in the docker-compose file by changing the password for example etc...

## Configuration
The following services are defined in the docker-compose.yml file:

- **nextcloud**: Nextcloud server container with the following environment variables:
```
    - MYSQL_HOST: hostname of the MariaDB container
    - MYSQL_DATABASE: database name for Nextcloud
    - MYSQL_USER: database username for Nextcloud
    - MYSQL_PASSWORD: database password for Nextcloud
    - OVERWRITEPROTOCOL: set to "https" to enable HTTPS
    - Volumes:
      - /root/docker_compose/nextcloud:/var/www/html
```

- **mariadb**: MariaDB database container with the following environment variables:
```
    - MYSQL_ROOT_PASSWORD: root password for MariaDB
    - MYSQL_DATABASE: database name for Nextcloud
    - MYSQL_USER: database username for Nextcloud
    - MYSQL_PASSWORD: database password for Nextcloud
    - Volumes:
      - /root/docker_compose/mariadb:/var/lib/mysql
```

- **nginx**: Nginx reverse proxy container with the following features:
```
    - HTTPS configuration
    - SSL certificate and key configured via the ssl directory
    - Proxy pass to the Nextcloud container
    - Volumes:
      - /root/docker_compose/nginx.conf:/etc/nginx/nginx.conf
```

## Nginx Configuration
The nginx.conf file defines the Nginx configuration for the reverse proxy. It includes the following features:

- HTTP to HTTPS redirect
- HTTPS configuration with SSL certificate and key
- Proxy pass to the Nextcloud container
- Security headers

## Conclusion
This docker-compose file and nginx configuration can be used to quickly set up a Nextcloud server with HTTPS enabled.
