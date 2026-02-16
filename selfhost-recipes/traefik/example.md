# Sample service behind Traefik

```yaml
services:
  my-app:
    image: traefik/whoami:v1.10
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`whoami.example.com`)"
      - "traefik.http.routers.my-app.entrypoints=web"
      - "traefik.http.routers.my-app.middlewares=https-redirect"
      - "traefik.http.routers.my-app-secure.rule=Host(`whoami.example.com`)"
      - "traefik.http.routers.my-app-secure.entrypoints=websecure"
      - "traefik.http.routers.my-app-secure.tls.certresolver=letsencrypt"
      - "traefik.http.services.my-app-secure.loadbalancer.server.port=80"
    networks:
      - traefik

networks:
  traefik:
    external: true
```
