# Mattermost

## Installation
1. Create data folders under `/var/docker/mattermost/volumes`.
2. Fill `.env` values (`TRAEFIK_HOST`, DB credentials, timezone).
3. Deploy `docker-compose.yml` via Portainer.
4. Verify `https://<TRAEFIK_HOST>` and complete first admin setup.
