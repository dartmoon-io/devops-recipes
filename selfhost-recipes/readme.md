# Selfhost recipes

## Prerequisites
- Install docker following [https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)
- We do not use docker volumes but we put everything inside `/var/docker/[SERVICE_NAME]/volumes/` folder to ease the backup process
- Use volumes only for data that can recreated from scatch (eg. cache, Let's Encrypt certificates, etc)
- Fix ufw to work with docker. Append the following lines lines to the file `/etc/ufw/after.rules`

```txt
# Put Docker behind UFW
*filter
:DOCKER-USER - [0:0]
:ufw-user-input - [0:0]

-A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-USER -m conntrack --ctstate INVALID -j DROP
-A DOCKER-USER -i eth0 -j ufw-user-input
-A DOCKER-USER -i eth0 -j DROP
COMMIT
```

and then reload ufw with `sudo ufw reload`

## Installation
### Install Portainer
1. Copy portainer `docker-compose.yml` and the `.env` files inside the host
2. Compile the `.env` with the domain associated to this portainer installation (eg. `portainer.yourdomain.io`)
3. Create the `traefik` network to prevent errors

```bash
docker network create -d bridge traefik
```
4. Launch portainer

```
docker-compose up -d
```

### Install of portainer-agent (where stacks will live)
1. Follow the same procedure described here [https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance](https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance)
2. Instead of launching the command, copy the portainer-agent `docker-compose.yml` and the `.env` files inside the host
3. Compile the `.env` with the data given to you by the step 1
4. Launch the portainer-agent

```
docker-compose up -d
```

## Usage
Inside each folder you will find the `docker-compose.yml` file and the `.env` file. To use them you need to feed the `docker-compose.yml` to Portainer and define each environment variable. The `.env` file is just a template for which environment variables must be defined.


## Resources
- [https://github.com/DoTheEvo/selfhosted-apps-docker/](https://github.com/DoTheEvo/selfhosted-apps-docker/)