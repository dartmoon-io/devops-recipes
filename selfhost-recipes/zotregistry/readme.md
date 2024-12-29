# Registry

# Installation
Simply feed the `docker-compose.yml` to Portainer and define all the environment variables that you will find inside the `.env` file.

Before starting the stack copy the files `config.json` and `htpasswd` inside the directory `/var/docker/zotregistry` on the host machine.

# Configuration
The `config.json` file is used to configure the registry. You can find more information about the configuration options [here](https://zotregistry.dev/).

# Basic Auth Authentication
Generate the htpasswd file using the following command:

```bash
htpasswd -bBn <username> <password>
```

Copy all users to the `htpasswd` file, one user per line.