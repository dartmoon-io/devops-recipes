# Outline (aka Brain)

# Installation
Simply feed the `docker-compose.yml` to Portainer and define all the environment variables that you will find inside the `.env` file.

# S3 Bucket
Outline needs a special configuration of the S3 bucket. Inside the `cors.json` you will find this configuration, so you just need to tweak the domain name and then configure your bucket. This is a provider-dependant configuration so follow the documentation of your provider.

For scaleway

1. Install and configure awscli as per [Amazon documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). Be aware that you must install a version prior to 2.22.35.

Configure the bucket following your provider. We are using [Scaleway](https://www.scaleway.com/en/docs/storage/object/api-cli/object-storage-aws-cli/).

eg.
File `~/.aws/config`
```txt
[default]
region = fr-par
output = json
services = scw-fr-par
s3 =
  max_concurrent_requests = 100
  max_queue_size = 1000
  multipart_threshold = 50 MB
  # Edit the multipart_chunksize value according to the file sizes that you
  # want to upload. The present configuration allows to upload files up to
  # 10 GB (1000 requests * 10 MB). For example, setting it to 5 GB allows you
  # to upload files up to 5 TB.
  multipart_chunksize = 10 MB
[services scw-fr-par]
s3 =
  endpoint_url = https://s3.fr-par.scw.cloud
```

File `~/.aws/credentials`
```txt
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

2. Set the bucket CORS configuration
```bash
aws s3api put-bucket-cors --bucket BUCKETNAME --cors-configuration file://cors.json
```