# Handling RunCloud with Self-Hosted Recipes

## Installation

>Assumptions:
>	- Root filesystem / is ext4 (e.g. /dev/sda1).
>	- You can schedule a short maintenance window (reboot + offline filesystem change).

1. Install quota tools and kernel extras

```bash
sudo apt update
sudo apt install -y quota linux-modules-extra-$(uname -r)
```

>Note: linux-modules-extra-$(uname -r) ensures quota support is available for ext4 on cloud/virtual kernels.

2. Enable ext4 native quota feature on the filesystem

From your provider’s rescue/live environment:

```bash
# Identify the root device (example: /dev/sda1)
lsblk

# Make sure it is not mounted
mount | grep sda1
sudo umount /dev/sda1    # only if it is mounted

# Enable ext4 "quota" feature and user/group quota types
sudo tune2fs -O quota /dev/sda1
sudo tune2fs -Q usrquota,grpquota /dev/sda1

# Run a full filesystem check after changing features
sudo e2fsck -f /dev/sda1
```
Then reboot the server normally from disk.

3. Configure /etc/fstab for quotas
On the normal system, edit /etc/fstab and add usrquota,grpquota to the root filesystem options:

```bash
sudo nano /etc/fstab
```

Example line:

```fstab
UUID=xxxx-xxxx  /  ext4  defaults,usrquota,grpquota  0  1
```

Apply changes:

```bash
sudo systemctl daemon-reload
sudo mount -o remount /
```

Verify that / is mounted with quota options:

```bash
grep " / " /proc/mounts
# -> should contain usrquota,grpquota
```

4. Initialize and enable quotas

Initialize quota accounting and enable user/group quotas on /:

```bash
sudo quotacheck -augm
sudo quotaon -vug /
```

Check status:

```bash
sudo quotaon -p /
```


Enable quota modules:
```bash
sudo modprobe quota_v1
sudo modprobe quota_v2
lsmod | grep quota
```

## Managing quotas

We will store all quota configuration in:

```bash
/etc/hosting
```

1. Create the directory with safe permissions

```bash
sudo mkdir -p /etc/hosting
sudo chown root:root /etc/hosting
sudo chmod 750 /etc/hosting
```

2. Copy the script into /usr/local/sbin/hosting.sh and give it executable permissions:

```bash
sudo nano /usr/local/sbin/hosting.sh
sudo chmod +x /usr/local/sbin/hosting.sh
```

3. File naming and format

For each client user (e.g. `c034_verdi`) there is a config file:

```text
/etc/hosting/c034_verdi.ini
```

Format (simple INI-like, one key of interest for now):

```ini
disk_quota=10GB
```

Meaning: **10 GB hard limit**.

Unlimited quota is expressed as:

```ini
disk_quota=-1
```

Meaning: **unlimited** (no disk quota limit is applied for that user).

Permissions for each file:

```bash
sudo chown root:root /etc/hosting/c034_verdi.ini
sudo chmod 640 /etc/hosting/c034_verdi.ini
```


## Cron job to enforce quotas

- Removes quota files for deleted users,
- Scans all “client” users (uid ≥ 1000, home under `/home`),
- Creates `/etc/hosting/<user>.ini` with `disk_quota=2GB` if missing,
- Applies the quotas (including `disk_quota=-1` for unlimited).


```bash
sudo nano /etc/cron.d/hosting
```

```bash
*/15 * * * * root /usr/local/sbin/hosting.sh sync >> /etc/hosting/cron.log 2>&1
```