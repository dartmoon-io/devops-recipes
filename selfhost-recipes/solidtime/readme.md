# Solidtime (Time tracking)

## Installation
1. Execute commands to generate the keys

```bash
sudo docker run -it --rm solidtime/solidtime:0.8.0 php artisan self-host:generate-keys
```
This command should be executed outside portainer. Copy the values inside the `.env` file.

2. Create storage directories

```bash
sudo mkdir -p /var/docker/solidtime/volumes/storage/app
sudo mkdir -p /var/docker/solidtime/volumes/storage/logs
```

Then fix the permissions:

```bash
sudo chown -R 1000:1000 /var/docker/solidtime/volumes/storage
```

## Resources
- [Docs](https://docs.solidtime.io/)