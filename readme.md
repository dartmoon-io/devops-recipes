# DevOps Receipts

## Prerequisites
- We do not use docker volumes but we put everything inside ´/var/docker/[SERVICE_NAME]/volumes/` folder to ease the backup process
- Use volumes only for data that can recreated from scatch (eg. cache, Let's Encrypt certificates, etc)
- Fix ufw to work with docker

## Configuration
Each docker-compose.yml must be loaded though Portainer

## Installation of portainer
1. Copy portainer `docker-compose.yml` and the `.env` files inside the host
2. Compile the `.env` with the domain associated to this portainer installation (eg. `portainer.yourdomain.ext`)
3. Create the `traefik` network to prevent errors
```bash
docker create network -d bridge traefik
```
4. Launch portainer
```
docker-compose up -d
```

## Installation of portainer-agent (where stack will live)
1. Follow the same procedure described here [https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance](https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance)
2. Instead of launching the command, copy the portainer-agent `docker-compose.yml` and the `.env` files inside the host
3. Compile the `.env` with the data given to you by the step 1
4. Launch the portainer-agent
```
docker-compose up -d
```

## Resources
- [https://github.com/DoTheEvo/selfhosted-apps-docker/](https://github.com/DoTheEvo/selfhosted-apps-docker/)