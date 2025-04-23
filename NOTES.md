# Notes around the Dockerfile + Entrypoint 



Passworks idea of using dockers is a bit 'off' / weird.. 
You need to attach the complete php / frontend code , by downloading it seperatly from the main containers.
But the 'normal' way of providing dockers would be that they just provide a docker image CONTAINING the latest version of their product.

This repo tries to mimic the NORMAL way by combining the 3 a 4 essential components:
- the latest repo/version of frontend (php/static)
- the php runtime settings (specific modules, etc.)
- the nginx http server , with specific settings and security considerations.
- the background/scheduled tasks executor 

into a single docker image. 

what is NOT included is
- the MongoDB service.
- let's ecnrypt support 

We ASSUME that you have your own ingress controller (Traefik , NGINX , that handles Let's encrypt for you)

The used 7.0 docker files were found here :
wget https://repos.passwork.pro/repository/docker/rc/passwork_compose_last.tar.gz

The latest code :
https://portal.passwork.pro/api/download?rc=yes&apikey=certificate_number


Nginx is (also) used as the httpserver .. for static content, security headers, etc. 
Their nginx settings makes it an integral part of the solution ..

So we include the repo/frontend + php-fpm + nginx , in 1 solution 



## Setup

This project combines:
- the docker/php-fpm dockerfile + entrypoint.sh
- the docker/nginx dockerfile + entrypoint.sh


### Notes and thoughts
changed the nginx ports to be 7080/7443 and NOT 80/443. 
because this container will probably live in a bigger eco system with other production traefik / loadbalancers, etc. 

nginx.conf pointed to php-fpm:9008 , 
the hostname php-fpm does not exists within a single docker. so changed it to 0.0.0.0 

skipped a lot of unnessary copying in the original 


we can skip the complete TINI stuff. 
It's never used except in the docker compose for the cron, but :
- tini is not necesssra there! 

Change
- command: ["tini", "--", "supercronic", "-quiet", "/server/schedule"]
- command: ["supercronic", "-quiet", "/server/schedule"]

supercronic is already well behaved , no need for tini.

We skip a seperate supercronic all together..



### List of usefull quic local commands

Quick access to commonly used commands during development 

`docker build --tag demo:0.1 .`
`docker run -it demo:0.1 /bin/bash`

`docker exec -it <dockerid> /bin/bash`

### Commands inside container

See /server/init 
- for the config.env and the token

in /server/www folder, you can execute ->
- php ./bin/console app:update
- php ./bin/console list
