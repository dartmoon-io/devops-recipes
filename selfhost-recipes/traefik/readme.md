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
