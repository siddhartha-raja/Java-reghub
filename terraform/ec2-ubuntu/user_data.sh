#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y \
  git \
  tree \
  unzip \
  curl \
  wget \
  jq \
  htop \
  net-tools \
  ca-certificates \
  gnupg \
  lsb-release

# Install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
./aws/install --update

# Create demo directory
mkdir -p /opt/java-reghub
echo "EC2 setup completed successfully" > /opt/java-reghub/setup-status.txt

# Optional: format and mount additional EBS volume if attached as /dev/xvdf or /dev/nvme1n1
DEVICE=""

if [ -b /dev/xvdf ]; then
  DEVICE="/dev/xvdf"
elif [ -b /dev/nvme1n1 ]; then
  DEVICE="/dev/nvme1n1"
fi

if [ -n "$DEVICE" ]; then
  if ! blkid "$DEVICE"; then
    mkfs.ext4 "$DEVICE"
  fi

  mkdir -p /data
  mount "$DEVICE" /data

  UUID=$(blkid -s UUID -o value "$DEVICE")
  echo "UUID=$UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab

  chmod 755 /data
fi