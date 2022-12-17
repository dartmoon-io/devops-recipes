# Sample service

```yaml
version: "3.3"

services:
    my-app:
        image: traefik/whoami:v1.7.1
        labels:
        - "traefik.enable=true"
        - "traefik.http.routers.my-app.rule=Host(`whoami.docker.test`)"
        - "traefik.http.routers.my-app.entrypoints=web"

        # - "traefik.http.routers.whoami.entrypoints=websecure"
        # - "traefik.http.routers.whoami.tls.certresolver=myresolver"
        # - "traefik.http.services.traefik.loadbalancer.server.port=8080"
        
        networks:
        - traefik
```