# Harbor (Container Registry)

## Installation
1. Download Harbor installer in `/var/docker/harbor/harbor`:
   <https://goharbor.io/docs/2.12.0/install-config/download-installer/>
2. Create required host directories:

```bash
mkdir -p /var/docker/harbor/data /var/docker/harbor/log
```

3. Rename `harbor.yml.tmpl` to `harbor.yml` and edit:
- Set `hostname` to your Harbor domain.
- Comment the `https` section (TLS is handled by Traefik).
- Set `external_url` to the same domain.
- Set `database.password`.
- Set `data_volume` to `/var/docker/harbor/data`.
- Set `log.local.location` to `/var/docker/harbor/log`.
- Set `log.level` to `warning`.
- Add S3 storage settings if used.

4. Run installer **without starting Harbor**:

```bash
./install.sh
```

5. Update generated compose to use absolute `/var/docker/harbor/harbor/common` paths and add Traefik labels/network for the `proxy` service.
6. Start Harbor:

```bash
docker compose up -d
```
