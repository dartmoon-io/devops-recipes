# Sample service behind Traefik (standard)

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
