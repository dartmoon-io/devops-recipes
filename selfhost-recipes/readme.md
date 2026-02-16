# Selfhost Recipes

## Overview
This directory contains Portainer-friendly recipes to deploy and operate self-hosted services.

## Principles
- Do not run services as `root` when avoidable.
- Store persistent data under `/var/docker/<service>/volumes/` for easier backup and restore.
- Keep all public services behind Traefik.
- Restrict host firewall rules with UFW and expose only required ports.

## Prerequisites
1. Install Docker Engine on Ubuntu: <https://docs.docker.com/engine/install/ubuntu/>
2. Install UFW and allow SSH:

```bash
sudo apt-get update
sudo apt-get install -y ufw
sudo ufw allow OpenSSH
sudo ufw enable
```

3. Put Docker behind UFW by appending the following block to `/etc/ufw/after.rules`:

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

Then reload UFW:

```bash
sudo ufw reload
```

## Installation flow
### 1) Portainer
1. Copy `selfhost-recipes/portainer/docker-compose.yml` and `.env` to the host.
2. Fill `.env` (especially `TRAEFIK_HOST`).
3. Start the stack:

```bash
docker compose up -d
```

### 2) Portainer Edge Agent (where stacks run)
1. Follow the official guide: <https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance>
2. Copy `selfhost-recipes/portainer-agent/docker-compose.yml` and `.env` to the target host.
3. Fill `.env` with the Edge values from Portainer.
4. Start the stack:

```bash
docker compose up -d
```

### 3) Traefik (reverse proxy)
1. Create the external network once:

```bash
docker network create traefik
```

2. Copy `selfhost-recipes/traefik/docker-compose.yml` and `.env` to the host.
3. Fill required variables (email, trusted IPs, dashboard host/auth).
4. Start the stack:

```bash
docker compose up -d
```

## Service deployment pattern
For each service folder:
1. Copy `docker-compose.yml` and optional support files to the host.
2. Fill `.env` variables.
3. Ensure required host folders exist under `/var/docker/<service>/volumes`.
4. Deploy via Portainer stack editor or `docker compose up -d`.

## Resources
- <https://github.com/DoTheEvo/selfhosted-apps-docker/>
