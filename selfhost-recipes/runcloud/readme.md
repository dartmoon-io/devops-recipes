# Handling RunCloud with Self-Hosted Recipes

## Installation

1. Install `quota` and dependencies:

```bash
sudo apt update
sudo apt install -y quota
sudo apt install -y linux-modules-extra-$(uname -r)
```

Enable modules
```bash
sudo modprobe quota_v1
sudo modprobe quota_v2
lsmod | grep quota
```

Make sure the modules are loaded on boot:

```bash
echo quota_v1 | sudo tee -a /etc/modules
echo quota_v2 | sudo tee -a /etc/modules
```

Reboot

```bash
sudo reboot
```

2. Add the `usrquota,grpquota` options:

```fstab
UUID=xxxx-xxxx  /  ext4  defaults,usrquota,grpquota  0  2
```

3. Remount and initialize quotas:

```bash
sudo mount -o remount /
sudo quotacheck -cum /
sudo quotacheck -cgm /
sudo quotaon -vug /
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