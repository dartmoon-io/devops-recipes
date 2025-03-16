# Harbor (Docker registry)

# Installation
1. Download the harbor installation script as described here `https://goharbor.io/docs/2.12.0/install-config/download-installer/` inside `/var/docker/harbor/harbor` folder
2. Create a folder named `data` and `log` inside `/var/docker/harbor` folder
3. Rename the file `harbor.yml.tmpl` to `harbor.yml`
4. Edit the `harbor.yml` changing:

- Change the `hostname` to your domain name
- Comment the `https` section: we are putting the registry behind traefik as a reverse proxy
- Uncommend and compile `external_url` with the same domain name as hostname
- Generare a password for the database and put it in `database.password`
- Change the `data_volume` to `/var/docker/harbor/data` 
- Change the `log.local.location` to `/var/docker/harbor/log` 
- Add the storage settings:
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
- Set the log level to `warning` inside `log.level`

5. Lauch the installation script with `./install.sh` and follow the instructions, but do not launch harbor
6. Edit the `docker-compose.yml` 

- Sustitute the `./common` with `/var/docker/harbor/harbor/common`
- Edit the `proxy` service:
```yaml
proxy:
  image: goharbor/nginx-photon:v2.12.2
  container_name: nginx
  restart: always
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
  logging:
    driver: "syslog"
    options:
      syslog-address: "tcp://localhost:1514"
      tag: "proxy"
```
- Add the `traefik` network
```yaml
networks:
  harbor:
    external: false
  traefik:
    external: true
```

7. Launch the harbor with `sudo docker compose up -d`