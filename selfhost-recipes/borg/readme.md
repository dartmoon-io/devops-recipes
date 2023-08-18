# Borg backup docker directories and volumes

0. Install and configure awscli and s3 bucket
```bash
sudo apt-get install awscli
sudo apt-get install pip
pip3 install awscli-plugin-endpoint
```

Configure the bucket [scaleway](https://www.scaleway.com/en/docs/storage/object/api-cli/object-storage-aws-cli/)

1. Copy the script into /var/borg
2. Add the script to the crontab to backup at 00:00 and 12:00 (server timestamp)

```txt
0 0 * * * /var/borg/backup.sh
0 12 * * * /var/borg/backup.sh
```

## Resources
- [https://github.com/luispabon/borg-s3-home-backup/blob/master/borg-backup.sh](https://github.com/luispabon/borg-s3-home-backup/blob/master/borg-backup.sh)
- [https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)