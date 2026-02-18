# n8n

## Installation
1. Copy `docker-compose.yml`, `.env`, and `init-data.sh` to host.
2. Fill `.env` (DB credentials, `TRAEFIK_HOST`, `ENCRYPTION_KEY`, timezone).
3. Ensure host folders exist under `/var/docker/n8n/volumes`.
4. Deploy via Portainer and wait for `postgres`, `redis`, `n8n`, and `n8n-worker` to become healthy.
