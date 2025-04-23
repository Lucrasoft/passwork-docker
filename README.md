# passwork-docker
A Docker file for [Passwork Pro](https://passwork.pro/).

It solves the problem of the official Passwork dockers, where you need to download the complete git repo on your host/volume.
The Passwork Git repo is preloaded into this docker image. You still require an official license and key from Passwork!

Image is based on the official php apache 8.0 docker base. 

## Usage 

You must provide one volume to the passwork container, as you can see in the docker-compose file

```
    volumes:
      # the init folder will contain (after initial setup) the generated keys and the config.env file
      - ./init:/server/init
```


Sample usage
```
docker run \ 
  -v ./init:/server/init 
  -p 7443:7443 \
  ghcr.io/lucrasoft/passwork-docker:7.0.10
```

## Mongo
The required MongoDB is not included in this docker and the setup assumes you provide it in a seperate docker service. 
Please use the provided docker-compose file as a starting point for deployment.

To manually add the mongodb on your docker host:
```
docker run -v ./database:/data/db -p 27017:27017 mongo:5.0.14-focal
```

## SSL
The container exposes http (port 80) only. 
To support SSL, you must provide this service via a reverse proxy, for example: Traefik or Nginx.


