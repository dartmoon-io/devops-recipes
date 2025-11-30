#!/usr/bin/env bash
#
# hosting.sh
#
# Per-user disk quota management based on:
#   /etc/hosting/<user>.ini
#
# - One config file per user: /etc/hosting/<user>.ini
# - Key:
#     disk_quota=10GB   # 10 GB hard limit
#     disk_quota=-1     # unlimited (no limit)
# - All limits are HARD (soft = hard).
# - If a config is missing or invalid, a default disk_quota of DEFAULT_DISK_QUOTA_GB is created.
# - Actions are logged to /etc/hosting/hosting.log
#
# Commands:
#   hosting.sh apply all                  Apply quotas for all client users (create default config if needed)
#   hosting.sh apply USER                 Apply quota for USER (create default config if needed)
#   hosting.sh set USER GB|-1|unlimited   Set quota for USER (GB integer or -1)
#   hosting.sh unset USER                 Remove quota for USER (set unlimited)
#   hosting.sh show USER                  Show config + current quota for USER, with consistency check
#   hosting.sh show                       Show config + current quota for ALL client users, plus orphan .ini list
#   hosting.sh purge                      Remove .ini files for users that no longer exist
#   hosting.sh sync                       Purge orphan configs, then apply quotas to all client users
#

set -euo pipefail

CONF_DIR="/etc/hosting"
LOG_FILE="${CONF_DIR}/hosting.log"

# Default quota in GB for new or invalid configs
DEFAULT_DISK_QUOTA_GB=2

# Users that must never be managed by this script
EXCLUDED_USERS=("root" "runcloud")

# Root path for client home directories (RunCloud users)
CLIENT_HOME_ROOT="/home"

# Filesystem mountpoint where quotas are enabled (ext4 with usrquota,grpquota)
QUOTA_FS="/"

# -----------------------
# Helpers: dirs & logging
# -----------------------

ensure_conf_dir() {
  mkdir -p "$CONF_DIR"
  chown root:root "$CONF_DIR"
  chmod 750 "$CONF_DIR"
}

ensure_log_perms() {
  chown root:root "$LOG_FILE" 2>/dev/null || true
  chmod 640 "$LOG_FILE" 2>/dev/null || true
}

log_quota_change() {
  # action: CREATE | UPDATE | DELETE
  # user:   username
  # old:    previous quota (string)
  # new:    new quota (string)
  # reason: short reason (manual-set, auto-default-missing, purge-orphan, ...)
  local action="$1"
  local user="$2"
  local old="$3"
  local new="$4"
  local reason="$5"

  ensure_conf_dir
  local ts
  ts=$(date -Iseconds)
  echo "$ts | action=${action} user=${user} old=${old} new=${new} reason=${reason}" >> "$LOG_FILE"
  ensure_log_perms
}

# Convert GB to KB (Linux quota uses KB units)
gb_to_kb() {
  local gb="$1"
  echo $(( gb * 1024 * 1024 ))
}

# Returns 0 if the user is excluded (e.g. root, runcloud), 1 otherwise
is_excluded_user() {
  local u="$1"
  for ex in "${EXCLUDED_USERS[@]}"; do
    [[ "$u" == "$ex" ]] && return 0
  done
  return 1
}

# -----------------------
# Config file handling
# -----------------------

# Read disk_quota from an .ini file.
# Output (stdout):
#   - "-1"  if disk_quota=-1 (unlimited)
#   - "N"   if disk_quota=NGB
# Return non-zero if invalid or missing.
read_quota_from_ini() {
  local file="$1"
  local line val

  line=$(grep -E '^disk_quota=' "$file" 2>/dev/null || true)
  [[ -z "$line" ]] && return 1

  val="${line#disk_quota=}"
  val="$(echo "$val" | tr -d '[:space:]')"  # strip whitespace

  # Unlimited
  if [[ "$val" == "-1" ]]; then
    echo "-1"
    return 0
  fi

  # NGB
  if [[ "$val" =~ ^([0-9]+)GB$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

# Get current config quota as a human string, for logging:
#   - "unlimited" if -1
#   - "<N>GB"     if NGB
#   - "invalid"   if file exists but line is invalid
#   - "none"      if file does not exist
get_config_quota_string() {
  local user="$1"
  local file="${CONF_DIR}/${user}.ini"

  if [[ ! -f "$file" ]]; then
    echo "none"
    return
  fi

  local q
  if q=$(read_quota_from_ini "$file"); then
    if [[ "$q" == "-1" ]]; then
      echo "unlimited"
    else
      echo "${q}GB"
    fi
  else
    echo "invalid"
  fi
}

# Write /etc/hosting/<user>.ini with the given value and log the change.
# value:
#   - "-1" for unlimited
#   - integer N for N GB
# reason:
#   - short description for the log (e.g. "manual-set", "auto-default-missing")
update_ini_with_logging() {
  local user="$1"
  local value="$2"
  local reason="$3"

  ensure_conf_dir
  local file="${CONF_DIR}/${user}.ini"
  local old_str
  old_str=$(get_config_quota_string "$user")

  local new_str

  if [[ "$value" == "-1" ]]; then
    echo "disk_quota=-1" > "$file"
    new_str="unlimited"
  else
    echo "disk_quota=${value}GB" > "$file"
    new_str="${value}GB"
  fi

  if [[ "$old_str" == "none" ]]; then
    log_quota_change "CREATE" "$user" "$old_str" "$new_str" "$reason"
  else
    log_quota_change "UPDATE" "$user" "$old_str" "$new_str" "$reason"
  fi

  chown root:root "$file"
  chmod 640 "$file"
}

# -----------------------
# Quota application
# -----------------------

# Apply quota for a single user, according to /etc/hosting/<user>.ini.
# Behaviour:
#   - If user is excluded: skip.
#   - If user does not exist: warn and skip.
#   - If home is not under CLIENT_HOME_ROOT: skip.
#   - If ini is missing: create it with DEFAULT_DISK_QUOTA_GB and log.
#   - If ini is invalid: overwrite with DEFAULT_DISK_QUOTA_GB and log.
#   - Then apply the quota with setquota on QUOTA_FS.
apply_quota_for_user() {
  local user="$1"

  # Exclude root / runcloud explicitly
  if is_excluded_user "$user"; then
    echo "[INFO] User $user is excluded from quota management, skipping."
    return
  fi

  # Get user info from /etc/passwd
  local line uid home
  line=$(getent passwd "$user" || true)
  [[ -z "$line" ]] && { echo "[WARN] User $user does not exist, skipping."; return; }

  uid=$(echo "$line"  | cut -d: -f3)
  home=$(echo "$line" | cut -d: -f6)

  # Only consider "client" users:
  #  - uid >= 1000
  #  - home under CLIENT_HOME_ROOT (e.g. /home/<user>)
  if [[ "$uid" -lt 1000 ]] || [[ "$home" != ${CLIENT_HOME_ROOT}/* ]]; then
    echo "[INFO] User $user (uid=$uid, home=$home) is not a client user, skipping."
    return
  fi

  local file="${CONF_DIR}/${user}.ini"
  local quota_value

  if [[ -f "$file" ]]; then
    if ! quota_value=$(read_quota_from_ini "$file"); then
      echo "[WARN] $file does not contain a valid disk_quota, using default ${DEFAULT_DISK_QUOTA_GB}GB."
      quota_value="$DEFAULT_DISK_QUOTA_GB"
      update_ini_with_logging "$user" "$quota_value" "auto-default-invalid"
    fi
  else
    echo "[INFO] No config file $file, creating default ${DEFAULT_DISK_QUOTA_GB}GB."
    quota_value="$DEFAULT_DISK_QUOTA_GB"
    update_ini_with_logging "$user" "$quota_value" "auto-default-missing"
  fi

  # quota_value is either "-1" (unlimited) or an integer > 0
  local soft hard

  if [[ "$quota_value" == "-1" ]]; then
    # Unlimited: 0 0 => no limits
    soft=0
    hard=0
    echo "[INFO] Setting unlimited quota for $user on $QUOTA_FS."
  else
    if [[ "$quota_value" -le 0 ]]; then
      echo "[WARN] disk_quota=${quota_value}GB for $user is not valid (<=0), skipping."
      return
    fi
    local limit_kb
    limit_kb=$(gb_to_kb "$quota_value")
    soft="$limit_kb"
    hard="$limit_kb"
    echo "[INFO] Setting quota for $user: ${quota_value}GB (SOFT=HARD=${limit_kb}KB) on $QUOTA_FS."
  fi

  /usr/sbin/setquota -u "$user" "$soft" "$hard" 0 0 "$QUOTA_FS"
}

# Apply quota to all "client" users:
#   - uid >= 1000
#   - home under CLIENT_HOME_ROOT
#   - excluding EXCLUDED_USERS
apply_all() {
  while IFS=: read -r username _ uid _ _ home _; do
    if [[ "$uid" -ge 1000 ]] && [[ "$home" == ${CLIENT_HOME_ROOT}/* ]]; then
      if is_excluded_user "$username"; then
        echo "[INFO] User $username is excluded from quota management, skipping."
        continue
      fi
      apply_quota_for_user "$username"
    fi
  done < /etc/passwd
}

# -----------------------
# High-level commands
# -----------------------

# Set quota for USER:
#   - GB integer: N     (NGB)
#   - GB string: NGB    (NGB)
#   - "-1" or "unlimited": unlimited
set_user_quota() {
  local user="$1"
  local arg="$2"

  if ! id "$user" >/dev/null 2>&1; then
    echo "[ERROR] User $user does not exist."
    exit 1
  fi

  # Prevent managing excluded users
  if is_excluded_user "$user"; then
    echo "[ERROR] User $user is excluded from quota management. Cannot set disk_quota."
    exit 1
  fi

  local value

  if [[ "$arg" == "-1" ]] || [[ "$arg" == "unlimited" ]]; then
    value="-1"
  elif [[ "$arg" =~ ^([0-9]+)$ ]]; then
    value="${BASH_REMATCH[1]}"
  elif [[ "$arg" =~ ^([0-9]+)GB$ ]]; then
    value="${BASH_REMATCH[1]}"
  else
    echo "[ERROR] Invalid quota value (use e.g. 2, 5, 10, 2GB or -1/unlimited)."
    exit 1
  fi

  if [[ "$value" != "-1" && "$value" -le 0 ]]; then
    echo "[ERROR] GB value must be > 0 or -1 for unlimited."
    exit 1
  fi

  update_ini_with_logging "$user" "$value" "manual-set"
  apply_quota_for_user "$user"
}

# Unset quota for USER:
#   - config: disk_quota=-1
#   - system: soft=0 / hard=0 (unlimited)
unset_user_quota() {
  local user="$1"

  if ! id "$user" >/dev/null 2>&1; then
    echo "[ERROR] User $user does not exist."
    exit 1
  fi

  if is_excluded_user "$user"; then
    echo "[ERROR] User $user is excluded from quota management. Cannot unset disk_quota."
    exit 1
  fi

  update_ini_with_logging "$user" "-1" "manual-unset"
  apply_quota_for_user "$user"
}

# Show orphan config files: ini files whose user does not exist anymore
show_orphan_configs() {
  echo "=== Orphan config files (no matching system user) ==="
  local found=false
  for file in "${CONF_DIR}"/*.ini; do
    [[ -e "$file" ]] || continue
    local user
    user=$(basename "$file" .ini)
    if ! id "$user" >/dev/null 2>&1; then
      echo " - $file (user '$user' does not exist)"
      found=true
    fi
  done
  $found || echo " - none"
  echo
}

# Remove orphan ini files and log the deletion
purge_orphan_configs() {
  ensure_conf_dir
  echo "Purging orphan config files in $CONF_DIR..."
  local found=false
  for file in "${CONF_DIR}"/*.ini; do
    [[ -e "$file" ]] || continue
    local user
    user=$(basename "$file" .ini)
    if ! id "$user" >/dev/null 2>&1; then
      local old_str
      old_str=$(get_config_quota_string "$user")
      echo "[PURGE] Removing $file (user '$user' does not exist)"
      rm -f -- "$file"
      log_quota_change "DELETE" "$user" "$old_str" "none" "purge-orphan"
      found=true
    fi
  done
  $found || echo "[PURGE] No orphan config files to remove."
}

# Full maintenance:
#   1) purge orphan configs
#   2) apply quotas to all client users
sync_quotas() {
  echo "[SYNC] Starting purge of orphan configs..."
  purge_orphan_configs
  echo "[SYNC] Purge completed. Applying quotas to all client users..."
  apply_all
  echo "[SYNC] Sync completed."
}

# Show config + system quota + consistency for ONE user
show_user() {
  local user="$1"
  local file="${CONF_DIR}/${user}.ini"

  echo "=================================================="
  echo "User: $user"
  echo "Config file: $file"

  local config_quota_valid=false
  local config_quota_value=""

  if [[ -f "$file" ]]; then
    echo "[CONFIG] File exists."
    if config_quota_value=$(read_quota_from_ini "$file"); then
      config_quota_valid=true
      if [[ "$config_quota_value" == "-1" ]]; then
        echo "[CONFIG] disk_quota = -1 (unlimited)"
      else
        echo "[CONFIG] disk_quota = ${config_quota_value}GB"
      fi
    else
      echo "[CONFIG] WARNING: invalid or missing disk_quota in file."
    fi
  else
    echo "[CONFIG] File does NOT exist."
    echo "[CONFIG] If you run 'apply' for this user, a default of ${DEFAULT_DISK_QUOTA_GB}GB will be created."
  fi

  echo
  echo "[SYSTEM] Current quota status (from 'quota -u $user'):"

  local quota_line
  quota_line=$(quota -u "$user" 2>/dev/null | awk 'NR==3 {print}')
  if [[ -z "$quota_line" ]]; then
    if [[ "$config_quota_valid" == true && "$config_quota_value" == "-1" ]]; then
      echo "  (no quota information: no limits recorded for this user)"
      echo
      echo "[OK] Config quota (unlimited) matches system state (no user limits set)."
    else
      echo "  (no quota information, user may have no quota set or filesystem is not using quotas)"
      echo
      echo "[INFO] Cannot compare config quota with system quota (no data from 'quota -u')."
    fi
    echo
    return
  fi

  local used_kb soft_kb hard_kb
  used_kb=$(awk '{print $2}' <<<"$quota_line")
  soft_kb=$(awk '{print $3}' <<<"$quota_line")
  hard_kb=$(awk '{print $4}' <<<"$quota_line")

  echo "  used=${used_kb}KB soft=${soft_kb}KB hard=${hard_kb}KB"

  local system_quota_desc=""
  local system_quota_is_unlimited=false

  if [[ "$soft_kb" -eq 0 && "$hard_kb" -eq 0 ]]; then
    system_quota_desc="unlimited"
    system_quota_is_unlimited=true
  else
    local system_gb=$(( hard_kb / 1024 / 1024 ))
    system_quota_desc="${system_gb}GB (from hard limit)"
  fi

  echo "  interpreted system quota: $system_quota_desc"
  echo

  # Compare config vs system
  if [[ "$config_quota_valid" == true ]]; then
    local config_desc
    if [[ "$config_quota_value" == "-1" ]]; then
      config_desc="unlimited"
      if [[ "$system_quota_is_unlimited" == true ]]; then
        echo "[OK] Config quota ($config_desc) matches system quota ($system_quota_desc)."
      else
        echo "[WARN] Config quota is $config_desc but system quota is $system_quota_desc."
      fi
    else
      config_desc="${config_quota_value}GB"
      local expected_kb
      expected_kb=$(gb_to_kb "$config_quota_value")
      if [[ "$hard_kb" -eq "$expected_kb" ]]; then
        echo "[OK] Config quota ($config_desc) matches system quota ($system_quota_desc)."
      else
        echo "[WARN] Config quota is $config_desc but system quota is $system_quota_desc."
      fi
    fi
  else
    echo "[INFO] No valid config quota to compare against system quota."
  fi

  echo
}

# Show summary for all client users + orphan configs
show_all_users() {
  # Orphan configs first
  show_orphan_configs

  # Then actual client users
  while IFS=: read -r username _ uid _ _ home _; do
    if [[ "$uid" -ge 1000 ]] && [[ "$home" == ${CLIENT_HOME_ROOT}/* ]]; then
      if is_excluded_user "$username"; then
        continue
      fi
      show_user "$username"
    fi
  done < /etc/passwd
}

# -----------------------
# CLI
# -----------------------

usage() {
  cat <<EOF
Usage:
  $0 apply all                  Apply quotas to all client users (creating default configs if needed)
  $0 apply USER                 Apply quota for USER (create default config if needed)
  $0 set USER GB|-1|unlimited   Set quota for USER (e.g. 2, 5, 10, -1, unlimited)
  $0 unset USER                 Remove quota for USER (set unlimited / disk_quota=-1)
  $0 show USER                  Show config + current quota for USER, with consistency check
  $0 show                       Show config + current quota for ALL client users, plus orphan .ini list
  $0 purge                      Remove .ini files for users that no longer exist
  $0 sync                       Purge orphan configs, then apply quotas to all client users

Notes:
  - Default disk_quota for new or invalid configs is ${DEFAULT_DISK_QUOTA_GB}GB.
  - disk_quota=-1 means unlimited (no quota limit).
  - Excluded users: ${EXCLUDED_USERS[*]}
  - Client homes: under ${CLIENT_HOME_ROOT}
  - Quota filesystem: ${QUOTA_FS}
  - Audit log: ${LOG_FILE}
EOF
}

main() {
  # If no arguments, print help and exit OK
  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi

  local cmd="${1:-}"
  case "$cmd" in
    apply)
      if [[ $# -lt 2 ]]; then
        usage
        exit 1
      fi
      if [[ "$2" == "all" ]]; then
        apply_all
      else
        apply_quota_for_user "$2"
      fi
      ;;
    set)
      [[ $# -ge 3 ]] || { usage; exit 1; }
      set_user_quota "$2" "$3"
      ;;
    unset)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      unset_user_quota "$2"
      ;;
    show)
      if [[ $# -eq 1 ]]; then
        show_all_users
      else
        show_user "$2"
      fi
      ;;
    purge)
      purge_orphan_configs
      ;;
    sync)
      sync_quotas
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"