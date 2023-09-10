# Backup Docker data directories and volumes

0. Install borg
```bash
sudo apt-get install borgbackup
```

1. Init the repo
```bash
mkdir -p /var/borg/repository
borg init --encryption=none /var/borg/repository
```

2. Install and configure awscli and s3 bucket
```bash
sudo apt-get install awscli
sudo apt-get install pip
pip3 install awscli-plugin-endpoint
```

Configure the bucket following your provider. We are using [Scaleway](https://www.scaleway.com/en/docs/storage/object/api-cli/object-storage-aws-cli/).

3. Copy the script inside `/var/borg` and set the variables `S3_BUCKET` and `S3_PROFILE` inside the script itself.
4. Add the script to the crontab to execute at 00:00 and 12:00 (server timestamp). This will trigger the backup. If you want to backup at different times or more often simply add other lines to your crontab.

To open the crontab in editing mode:
```bash
crontab -e
```

These are the cronjobs to set.

```txt
0 0 * * * /var/borg/backup.sh
0 12 * * * /var/borg/backup.sh
```

Done!

## Resources
- [https://github.com/luispabon/borg-s3-home-backup/blob/master/borg-backup.sh](https://github.com/luispabon/borg-s3-home-backup/blob/master/borg-backup.sh)
- [https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)