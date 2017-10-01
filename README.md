# Encrypted Dashboard based on docker
## + Nginx + Let's Encrypt + Rstudio + Shiny based on custom made debian full with different libraries and an R version with a lot of pre-installed libraries.

----
### NEED TO HAVE
Up to date - please open an issue or commit new things

### NICE TO HAVE
Add a netdata.io docker to monitor the performance of the setup.     
Add a postgres docker as an example of a connected database.

----

Basically I started with the code from these two repos:

https://github.com/gilyes/docker-nginx-letsencrypt-sample .    
https://github.com/fatk/docker-letsencrypt-nginx-proxy-companion-examples .     


What they did was to create a website running behind a dockerized Nginx reverse proxy and served via HTTPS using free [Let's Encrypt](https://letsencrypt.org) certificates. New sites could be added on the fly by just modifying `docker-compose.yml` and then running `docker-compose up` as the main Nginx config is automatically updated and certificates (if needed) are automatically acquired.

# BUT

I wanted to build an encrypted Shiny Dashboard with an Rstudio Server that would run in separate docker containers and be served at different urls.

The problem here is to share settings, code and libraries between the two docker containers. In order to do that I have done the following:

### Debian image
I have created a custom debian image that basically installs all the libraries needed for linux to install R, Shiny and Rstudio along with a lot dependencies for different R packages. I did this to lay a common foundation for the R image and the following Shiny and Rstudio images. They need the same infrastructure to work properly.
You can inspect the docker file in the debian folder and pull the image from: https://hub.docker.com/r/mikkelkrogsholm/debian/

### R image
I built my own R image on top of the debian image.
You can inspect the docker file in the r folder and pull the image from: https://hub.docker.com/r/mikkelkrogsholm/r-base/

### Rstudio and Shiny
Both Rstudio and Shiny are then built on top of the R image. This means that they all share the same dependencies and libraries. There shouldn't be any problem transferring R code from Rstudio to Shiny since the underlying R image is the same and they don't have different dependencies installed on the linux side.

You can inspect the Rstudio docker file in the rstudio folder and pull the image from: https://hub.docker.com/r/mikkelkrogsholm/rstudio/

You can inspect the Shiny docker file in the shiny folder and pull the image from: https://hub.docker.com/r/mikkelkrogsholm/shiny/


## Setup your dashboard

### Preparation
* Clone the [repository](https://github.com/mikkelkrogsholm/encrypted_dashboard) on the server pointed to by your domain.
* In `docker-compose.yml`:
* Choose if you want a single user setup or multiuser setup in Rstudio.
* Change the **VIRTUAL_HOST** and **LETSENCRYPT_HOST** entries from *rstudio.mydomain.com* and *shiny.mydomain.com* to your domains.
* Change **LETSENCRYPT_EMAIL** entries to the email address you want to be associated with the certificates.
* Change **USER** and **PASSWORD** entries to the user and password you want for Rstudio.

### Running
In the main directory run:
```bash
docker-compose up
```

This will perform the following steps:

* Download the required images from Docker Hub ([nginx](https://hub.docker.com/_/nginx/), [docker-gen](https://hub.docker.com/r/jwilder/docker-gen/), [docker-letsencrypt-nginx-proxy-companion](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion/)).
* Create containers from them.
* Build and create containers for Rstudio Server and Shiny Server
* Start up the containers.
  * *docker-letsencrypt-nginx-proxy-companion* inspects containers' metadata and tries to acquire certificates as needed (if successful then saving them in a volume shared with the host and the Nginx container).
  * *docker-gen* also inspects containers' metadata and generates the configuration file for the main Nginx reverse proxy
* Sets up a Watchtower docker - Watchtower is a process for watching your Docker containers and automatically updating and restarting them whenever their base image is refreshed.

If everything went well then you should now be able to access Rstudio and Shiny and the given addresses.

### Troubleshooting
* To view logs run `docker-compose logs`.
* To view the generated Nginx configuration run `docker exec -ti nginx cat /etc/nginx/conf.d/default.conf`

## How does it work

The system consists of 5 main parts:

* Main Nginx reverse proxy container.
* Container that generates the main Nginx config based on container metadata.
* Container that automatically handles the acquisition and renewal of Let's Encrypt TLS certificates.
* The actual servers living in their own containers. In this example Rstudio and Shiny.
* A watchtower container to keep everythinng up-to-date.

### The main Nginx reverse proxy container
This is the only publicly exposed container, routes traffic to the backend servers and provides TLS termination.

Uses the official [nginx](https://hub.docker.com/_/nginx/) Docker image.

It is defined in `docker-compose.yml` under the **nginx** service block:

```
services:
  nginx:
    restart: always
    image: nginx
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/etc/nginx/conf.d"
      - "/etc/nginx/vhost.d"
      - "/usr/share/nginx/html"
      - "./volumes/proxy/certs:/etc/nginx/certs:ro"
```

As you can see it shares a few volumes:
* Configuration folder: used by the container that generates the configuration file.
* Default Nginx root folder: used by the Let's Encrypt container for challenges from the CA.
* Certificates folder: written to by the Let's Encrypt container, this is where the TLS certificates are maintained.

### The configuration generator container
This container inspects the other running containers and based on their metadata (like **VIRTUAL_HOST** environment variable) and a template file it generates the Nginx configuration file for the main Nginx container. When a new container is spinning up this container detects that, generates the appropriate configuration entries and restarts Nginx.

Uses the [jwilder/docker-gen](https://hub.docker.com/r/jwilder/docker-gen/) Docker image.

It is defined in `docker-compose.yml` under the **nginx-gen** service block:

```
services:
  ...

  nginx-gen:
    restart: always
    image: jwilder/docker-gen
    container_name: nginx-gen
    volumes:
      - "/var/run/docker.sock:/tmp/docker.sock:ro"
      - "./volumes/proxy/templates/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro"
    volumes_from:
      - nginx
    entrypoint: /usr/local/bin/docker-gen -notify-sighup nginx -watch -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
```

The container reads the `nginx.tmpl` template file (source: [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy)) via a volume shared with the host.

It also mounts the Docker socket into the container in order to be able to inspect the other containers (the `"/var/run/docker.sock:/tmp/docker.sock:ro"` line).
**Security warning**: mounting the Docker socket is usually discouraged because the container getting (even read-only) access to it can get root access to the host. In our case, this container is not exposed to the world so if you trust the code running inside it the risks are probably fairly low. But definitely something to take into account. See e.g. [The Dangers of Docker.sock](https://raesene.github.io/blog/2016/03/06/The-Dangers-Of-Docker.sock/) for further details.

NOTE: it would be preferable to have docker-gen only handle containers with exposed ports (via `-only-exposed` flag in the `entrypoint` script above) but currently that does not work, see e.g. <https://github.com/jwilder/nginx-proxy/issues/438>.

### The Let's Encrypt container
This container also inspects the other containers and acquires Let's Encrypt TLS certificates based on the **LETSENCRYPT_HOST** and **LETSENCRYPT_EMAIL** environment variables. At regular intervals it checks and renews certificates as needed.

Uses the [jrcs/letsencrypt-nginx-proxy-companion](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion/) Docker image.

It is defined in `docker-compose.yml` under the **letsencrypt-nginx-proxy-companion** service block:

```
services:
  ...

  letsencrypt-nginx-proxy-companion:
    restart: always
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: letsencrypt-nginx-proxy-companion
    volumes_from:
      - nginx
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./volumes/proxy/certs:/etc/nginx/certs:rw"
    environment:
      - NGINX_DOCKER_GEN_CONTAINER=nginx-gen
```

The container uses a volume shared with the host and the Nginx container to maintain the certificates.

It also mounts the Docker socket in order to inspect the other containers. See the security warning above in the docker-gen section about the risks of that.

### The Rstudio Server and Shiny Server
This example shows the single user case. These two servers are running in their own respective containers. They are defined in `docker-compose.yml` under the **tidyverse** and **shiny** service blocks:

```
services:
  ...

  tidyverse:
    restart: always
    image: mikkelkrogsholm/rstudio
    container_name: rstudio
    expose:
      - "8787"
    environment:
      - VIRTUAL_HOST=rstudio.mydomain.com
      - VIRTUAL_NETWORK=nginx-proxy
      - VIRTUAL_PORT=80
      - LETSENCRYPT_HOST=rstudio.mydomain.com
      - LETSENCRYPT_EMAIL=me@myemail.com
      - USER=test
      - PASSWORD=test
    volumes:
      - shiny-apps:/home/mikkel/apps
      - r-packages:/usr/local/lib/R/site-library

  shiny:
    restart: always
    image: mikkelkrogsholm/shiny
    container_name: shiny
    expose:
      - "3838"
    environment:
      - VIRTUAL_HOST=shiny.mydomain.com
      - VIRTUAL_NETWORK=nginx-proxy
      - VIRTUAL_PORT=80
      - LETSENCRYPT_HOST=shiny.mydomain.com
      - LETSENCRYPT_EMAIL=me@myemail.com
    volumes:
      - shiny-apps:/srv/shiny-server/
      - ./volumes/shiny/logs:/var/log/
      - r-packages:/usr/local/lib/R/site-library
```
The important part here are the environment variables and the volumes. The environment variables are used by the config generator and certificate maintainer containers to set up the system.

### The Watchtower container
The Watchtower service will look for new images every midnight and update and restart the other docker containers if they update. You can change the update schedule under schedule. It also removes the old containers.

```
services:
  ...

  watchtower:
    image: v2tec/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/.docker/config.json:/config.json
    command:
      --schedule "0 0 0 *" # Look for new images every midnight
      --cleanup # Removes old images
```

### The data volumes

The volumes are used to ensure that Rstudio and Shiny share apps and packages in order for you to build apps in Rstudio and have them deployed on the Shiny server without too big a hassle.

```
volumes:
  shiny-apps: # holds the shiny apps
  r-packages: # holds new common libraries
  backup: # makes backup of the /home folder in Rstudio docker.
```

## Conclusion
This can be a fairly simple way to have easy, reproducible deploys for a secure R-based dashboard solution with auto-renewing TLS certificates.
