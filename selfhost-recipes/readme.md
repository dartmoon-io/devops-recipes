# Selfhost Recipes

## Important
Do not run Docker or public services as root. Always create a dedicated user where possible.

```bash
sudo adduser ubuntu
sudo usermod -aG sudo ubuntu
```

## Prerequisites
- Install Docker: <https://docs.docker.com/engine/install/ubuntu/>
- Store persistent data under `/var/docker/<service>/volumes/` to simplify backups.
- Use named Docker volumes only for data that can be recreated (for example cache).
- Enable UFW:

```bash
sudo apt-get update
sudo apt-get install -y ufw
sudo ufw allow OpenSSH
sudo ufw enable
```

- Put Docker behind UFW by appending this block to `/etc/ufw/after.rules`:

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

## Docker Compose standard (mandatory)
Use this standard for every `docker-compose.yml` in this directory.

### Global rules
- Do not use `version:`.
- Keep section order: `services` → `networks` → `volumes`.
- Use `restart: unless-stopped` by default.
- Keep names clean and consistent (service name must match product name).

### Service field order
Inside each service, keep this order when applicable:
1. `image`
2. `container_name` (only when needed)
3. `env_file` / `environment`
4. `volumes`
5. `ports`
6. `labels`
7. `depends_on`
8. `healthcheck`
9. `restart`
10. `networks`

### Traefik exposure pattern
For web-exposed services:
- Always set `traefik.enable=true`.
- Always define both routers:
  - `<service>` on `web` + `https-redirect`
  - `<service>-secure` on `websecure` + TLS certresolver
- Always define backend port:
  - `traefik.http.services.<service>-secure.loadbalancer.server.port=<internal_port>`
- Attach service to external `traefik` network.

Use the Traefik templates in:
- `selfhost-recipes/traefik/readme.md`
- `selfhost-recipes/traefik/example.md`

## Installation
### Install Portainer
1. Copy `selfhost-recipes/portainer/docker-compose.yml` and `.env` to the host.
2. Fill `.env` with the domain for this Portainer instance (for example `portainer.yourdomain.io`).
3. Create the Traefik network (required by multiple stacks):

```bash
docker network create traefik
```

4. Start Portainer:

```bash
docker compose up -d
```

### Install Portainer Agent (where stacks run)
1. Follow: <https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance>
2. Copy `selfhost-recipes/portainer-agent/docker-compose.yml` and `.env` to the target host.
3. Fill `.env` using values from Portainer Edge setup.
4. Start the agent:

```bash
docker compose up -d
```

### Launch Traefik stack
1. Open Portainer at `https://localhost:9443/#!/internal-auth`.
2. Create a new stack and paste `selfhost-recipes/traefik/docker-compose.yml`.
3. Fill all environment variables from `selfhost-recipes/traefik/.env`.
4. Deploy the stack.

## Usage
Each service folder contains `docker-compose.yml` and usually a `.env` template.
- Use the compose file in Portainer stack deployment.
- Define all required environment variables.
- Create required host directories under `/var/docker/<service>/volumes` before deployment.

## Resources
- <https://github.com/DoTheEvo/selfhosted-apps-docker/>
