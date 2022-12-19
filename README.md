# passwork-docker
A Docker file for Passwork Pro.

It solves the problem of the official Passwork dockers, where you need a complete git repo on your host/volume.
This Passwork Git repo is preloaded into this docker image. You still require an official license and key from Passwork!

Image is based on the official php apache 8.0 docker base. 

## Usage 

You must provide 2 volumes.
- One is the `config.ini` which you can download from this repo as a starting point. Update the secret!
- One is the folder 'keys', where the system stores the provided license key.

> Make sure you edit the secret in `config.ini` file before starting the container and setting up the mongodb!

Sample usage
```
docker create \ 
  -v ./config.ini:/var/www/app/config/config.ini \ 
  -v ./keys:/var/www/app/keys \ 
  -p:8080:80 \
  ghcr.io/lucrasoft/passwork-docker:0.1.3
```

## Mongo
The required MongoDB is not included in this docker and the setup assumes you provide it in a seperate docker service. 
Please use the provided docker-compose file as a starting point for deployment.


## SSL
The container exposes http (port 80).  
To support SSL, you must provide this service via a reverse proxy, for example: Traefik or Nginx.


