#!/bin/bash

# INITIALIZE THE REPO WITH THE COMMAND:
#   borg init --encryption=none /var/borg/repository
# THEN RUN THIS SCRIPT

# -----------------------------------------------

BACKUP_THIS='/var/docker'
REPOSITORY='/var/borg/repository'
LOGFILE='/var/borg/borg.log'
S3_BUCKET=
S3_PROFILE=default


# -----------------------------------------------

NOW=$(date +"%Y-%m-%d | %H:%M | ")
echo "$NOW Starting Backup and Prune" >> $LOGFILE

# CREATES NEW ARCHIVE IN PRESET REPOSITORY

borg create                                     \
    $REPOSITORY::'{now:%s}'                     \
    $BACKUP_THIS                                \
                                                \
    --compression zstd                          \
    --one-file-system                           \
    --exclude-caches                            \
    --exclude-if-present '.nobackup'            \

# DELETES ARCHIVES NOT FITTING KEEP-RULES

borg prune -v --list $REPOSITORY                \
    --keep-hourly=24                            \
    --keep-daily=7                              \
    --keep-weekly=4                             \
    --keep-monthly=6                            \
    --keep-yearly=0                             \

echo "$NOW Starting to backup repo to S3" >> $LOGFILE

# BACKUP REPO TO S3
aws s3 sync $REPOSITORY s3://$S3_BUCKET --profile=$S3_PROFILE --delete

echo "$NOW Done" >> $LOGFILE
echo '------------------------------' >> $LOGFILE

# --- USEFULL SHIT ---

# setup above ignores directories containing '.nobackup' file
# make '.nobackup' imutable using chattr to prevent accidental removal
#   touch .nobackup
#   chattr +i .nobackup

# in the repo folder, to list available backups:
#   borg list .
# to mount one of them:
#   borg mount .::1584472836 ~/temp
# to umount:
#   borg umount ~/temp
# to delete single backup in a repo:
#   borg delete .::1584472836