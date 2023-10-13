#!/bin/bash

# Set Ceph configuration parameters in ceph.conf
set -x
# Define the path to the ceph.conf file
config_file="ceph_conf/ceph.conf"

# Configuration settings to update
config_settings=(
    "max open files = 655350"
    "cephx cluster require signatures = false"
    "cephx service require signatures = false"
    "mon_osd_allow_reclaim = false"
    "mon_max_pg_per_osd = 800"
    "[osd]"
    "osd_journal_size = 5120"
    "osd_memory_target = 512MB"
    "osd_pool_default_size = 3"
    "osd_pool_default_min_size = 2"
    "osd_pool_default_pg_num = 333"
    "osd_crush_chooseleaf_type = 1"
)

# Function to check if a section header already exists in the file
section_exists() {
    local section="$1"
    grep -q "\[$section\]" "$config_file"
}

# Loop through the configuration settings and update the ceph.conf file
for setting in "${config_settings[@]}"; do
  # Check if the setting already exists in the file
  if [[ "$setting" == "["* ]]; then
      # Add the section header to the ceph.conf file
      # This is a section header, check if it already exists in the file
       section_name="${setting:1:${#setting}-2}" # Extract the section name
       if ! section_exists "$section_name"; then
         # If the section doesn't exist, add it to the ceph.conf file
          echo "$setting" | sudo tee -a "$config_file"
       fi
  elif grep -q "${setting%=*}" "$config_file"; then
    # Replace the existing line with the new setting
    sed -i "s|${setting%=*}.*|${setting}|" "$config_file"
  else
    # If the setting doesn't exist, add it to the end of the file
    echo "$setting" | sudo tee -a "$config_file"
  fi
done

# Create an administrator password file
echo "administrator_password" > ceph_conf/ceph_password.txt

# Get the operating system type
OS=$(uname -s)

# Define the Docker Compose command based on the OS
if [ "$OS" = "Darwin" ]; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif [ "$OS" = "Linux" ]; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

# Restart Ceph components to apply changes without health warnings
$DOCKER_COMPOSE_CMD restart ceph-mon ceph-mgr
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool create default.rgw.buckets.data 512 512
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool application enable default.rgw.buckets.data rgw
