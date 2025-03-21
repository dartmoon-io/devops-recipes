# Backup Docker data directories and volumes

Execute the following steps as root.

0. Install borg
```bash
apt-get install borgbackup
```

1. Init the repo
```bash
mkdir -p /var/borg/repository
borg init --encryption=none /var/borg/repository
```

2. Install and configure awscli as per [Amazon documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). Be aware that you must install a version prior to 2.22.35

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


3. Copy the script inside `/var/borg` and set the variables `S3_BUCKET` and `S3_PROFILE` inside the script itself.
4. Add the script to the crontab to execute when you want to make the backup (server timestamp). This will trigger the backup. If you want to backup at different times or more often simply add other lines to your crontab.

To open the crontab in editing mode:
```bash
crontab -e
```

These are the cronjobs to set.

```txt
0 0 * * * /var/borg/backup.sh
0 4 * * * /var/borg/backup.sh
0 8 * * * /var/borg/backup.sh
0 12 * * * /var/borg/backup.sh
0 16 * * * /var/borg/backup.sh
0 20 * * * /var/borg/backup.sh
```

Done!

# Restore from backup
Execute the steps from (0)-(2), without initializing the repository.

Then execute the following command to download the repository from s3 to the local machine.

```bash
aws s3 cp s3://[BUCKET_NAME] /var/borg/repository --recursive
```

where `[BUCKET_NAME]` is the name of the bucket where the repository is stored.

Verify the repository with the following command:

```bash
borg list /var/borg/repository
```

Create the docker volume directory
```bash
mkdir -p /var/docker
```

Then you can restore the data to the local path with the following command:

```bash
cd /
borg extract /var/borg/repository::[ARCHIVE_NAME]
```

where `[ARCHIVE_NAME]` is the name of the archive you want to restore.

## Resources
- [https://github.com/luispabon/borg-s3-home-backup/blob/master/borg-backup.sh](https://github.com/luispabon/borg-s3-home-backup/blob/master/borg-backup.sh)
- [https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)