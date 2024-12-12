# Registry

# Installation
Simply feed the `docker-compose.yml` to Portainer and define all the environment variables that you will find inside the `.env` file.

# Auth
You need to create the password file for the registry. You can use the `htpasswd` command to do this. Here is an example:

```bash
echo $(htpasswd -nB user) | sed -e s/\\$/\\$\\$/g
```

then add it to the `REGISTRY_BASIC_AUTH_USERS` environment variable. Multiple users can be added by separating them with a comma.

# S3 Bucket
Outline needs a special configuration of the S3 bucket. Inside the `cors.json` you will find this configuration, so you just need to tweak the domain name and then configure your bucket. This is a provider-dependant configuration so follow the documentation of your provider.