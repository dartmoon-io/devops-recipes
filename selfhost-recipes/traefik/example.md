# Sample service

```yaml
version: "3.3"

services:
    my-app:
        image: traefik/whoami:v1.7.1
        labels:
        - "traefik.http.routers.my-app.rule=Host(`whoami.docker.test`)"
        - "traefik.http.routers.my-app.entrypoints=web"
        - "traefik.http.routers.my-app.middlewares=https-redirect"
        - "traefik.http.routers.my-app-secure.rule=Host(`whoami.docker.test`)"
        - "traefik.http.routers.my-app-secure.entrypoints=websecure"
        - "traefik.http.routers.my-app-secure.tls.certresolver=letsencrypt"
        - "traefik.http.services.my-app-secure.loadbalancer.server.port=8080"

        networks:
        - traefik
```