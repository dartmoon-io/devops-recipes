# Traefik

## Installation
1. Create external Docker network once:

```bash
docker network create traefik
```

2. Fill `.env` values:
- `LETSENCRYPT_ACME_EMAIL`
- `TRUSTED_IPS`
- `TRAEFIK_DASHBOARD_HOST`
- `TRAEFIK_DASHBOARD_AUTH` (htpasswd format)

3. Deploy stack via Portainer.

4. Verify:
- HTTP redirects to HTTPS
- certificate issuance works
- dashboard is reachable only at `https://<TRAEFIK_DASHBOARD_HOST>` with auth

## Standard labels pattern (copy/paste)
Use this pattern for every web-exposed service:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<service>.rule=Host(`${TRAEFIK_HOST}`)"
  - "traefik.http.routers.<service>.entrypoints=web"
  - "traefik.http.routers.<service>.middlewares=https-redirect"
  - "traefik.http.routers.<service>-secure.rule=Host(`${TRAEFIK_HOST}`)"
  - "traefik.http.routers.<service>-secure.entrypoints=websecure"
  - "traefik.http.routers.<service>-secure.tls.certresolver=letsencrypt"
  - "traefik.http.services.<service>-secure.loadbalancer.server.port=<internal_port>"
```

## Sample service behind Traefik (standard)

```yaml
services:
  my-app:
    image: traefik/whoami:v1.10
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`${TRAEFIK_HOST}`)"
      - "traefik.http.routers.my-app.entrypoints=web"
      - "traefik.http.routers.my-app.middlewares=https-redirect"
      - "traefik.http.routers.my-app-secure.rule=Host(`${TRAEFIK_HOST}`)"
      - "traefik.http.routers.my-app-secure.entrypoints=websecure"
      - "traefik.http.routers.my-app-secure.tls.certresolver=letsencrypt"
      - "traefik.http.services.my-app-secure.loadbalancer.server.port=80"
    restart: unless-stopped
    networks:
      - traefik

networks:
  traefik:
    external: true
```

## Compose conventions reminder
- No `version:`
- `restart: unless-stopped`
- service field order: image → env → volumes → ports → labels → depends_on → healthcheck → restart → networks
