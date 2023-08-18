# Selfhost receipts

## Prerequisites
- We do not use docker volumes but we put everything inside `/var/docker/[SERVICE_NAME]/volumes/` folder to ease the backup process
- Use volumes only for data that can recreated from scatch (eg. cache, Let's Encrypt certificates, etc)
- Fix ufw to work with docker ([Here](https://github.com/chaifeng/ufw-docker) a guide to do it)

## Installation
### Install Portainer
1. Copy portainer `docker-compose.yml` and the `.env` files inside the host
2. Compile the `.env` with the domain associated to this portainer installation (eg. `portainer.yourdomain.io`)
3. Create the `traefik` network to prevent errors

```bash
docker create network -d bridge traefik
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
Inside each you will find the `docker-compose.yml` file and the `.env` file. To use them you need to feed the `docker-compose.yml` to Portainer and define each environment variable. The `.env` file is just a template for what environment variables must be defined.


## Resources
- [https://github.com/DoTheEvo/selfhosted-apps-docker/](https://github.com/DoTheEvo/selfhosted-apps-docker/)