# Harbor (Container Registry)

## Installation
1. Download the Harbor installer into `/var/docker/harbor/harbor`:
   <https://goharbor.io/docs/2.12.0/install-config/download-installer/>
2. Create required folders:

```bash
mkdir -p /var/docker/harbor/data /var/docker/harbor/log
```

3. Rename `harbor.yml.tmpl` to `harbor.yml`.
4. Edit `harbor.yml`:
- Set `hostname` to your domain.
- Comment the `https` section (TLS is handled by Traefik).
- Set `external_url` with the same domain.
- Set `database.password`.
- Set `data_volume` to `/var/docker/harbor/data`.
- Set `log.local.location` to `/var/docker/harbor/log`.
- Set `log.level` to `warning`.
- Add storage settings if using S3:

```yaml
storage_service:
  type: s3
  s3:
    accesskey: ACCESSKEY
    secretkey: SECRETKEY
    region: REGION
    regionendpoint: ENDPOINT
    bucket: BUCKET
    secure: true
    skipverify: false
    rootdirectory: /
    forcepathstyle: true
```

5. Run install script but do not start Harbor yet:

```bash
./install.sh
```

6. Edit generated `docker-compose.yml`:
- Replace `./common` with `/var/docker/harbor/harbor/common`.
- Update `proxy` service and add Traefik labels/network:

```yaml
proxy:
  image: goharbor/nginx-photon:v2.12.2
  container_name: nginx
  restart: unless-stopped
  cap_drop:
    - ALL
  cap_add:
    - CHOWN
    - SETGID
    - SETUID
    - NET_BIND_SERVICE
  volumes:
    - /var/docker/harbor/harbor/common/config/nginx:/etc/nginx:z
    - type: bind
      source: /var/docker/harbor/harbor/common/config/shared/trust-certificates
      target: /harbor_cust_cert
  networks:
    - harbor
    - traefik
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.harbor.rule=Host(`${TRAEFIK_HOST}`)"
    - "traefik.http.routers.harbor.entrypoints=web"
    - "traefik.http.routers.harbor.middlewares=https-redirect"
    - "traefik.http.routers.harbor-secure.rule=Host(`${TRAEFIK_HOST}`)"
    - "traefik.http.routers.harbor-secure.entrypoints=websecure"
    - "traefik.http.routers.harbor-secure.tls.certresolver=letsencrypt"
    - "traefik.http.services.harbor-secure.loadbalancer.server.port=8080"
    - "traefik.http.services.harbor-secure.loadbalancer.server.scheme=http"
  depends_on:
    - registry
    - core
    - portal
    - log
```

- Ensure networks section includes Traefik:

```yaml
networks:
  harbor:
    external: false
  traefik:
    external: true
```

7. Start Harbor:

```bash
docker compose up -d
```
