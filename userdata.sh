#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Update & upgrade
apt-get update -y
apt-get upgrade -y

curl -fsSL https://get.docker.com -o get-docker.sh
chmod 755 get-docker.sh
./get-docker.sh

## Variables for certbot
# update if you change the vars in var.tf
DOMAIN=""
EMAIL="connor.fryar@ibm.com" 
KEYTYPE="rsa"               

# 1) Ensure certbot is available
if ! command -v certbot >/dev/null 2>&1; then
  sudo snap install --classic certbot
  sudo ln -sf /snap/bin/certbot /usr/bin/certbot
fi

# 4) Obtain/renew non-interactively
if [[ -n $DOMAIN ]]; then  
  sudo certbot certonly --standalone \
    -d "${DOMAIN}" \
    --key-type "${KEYTYPE}" \
    --non-interactive --agree-tos -m "${EMAIL}" \

  # Define target destination
  TARGET_DIR="/opt/$TARGET_DIR"
  # make working directory
  sudo mkdir -p /opt/$TARGET_DIR
  # make certs directory
  sudo mkdir -p /opt/$TARGET_DIR/certs
  # move certificates
  sudo cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "$TARGET_DIR/certs/bundle.pem"
  sudo cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "$TARGET_DIR/certs/cert.pem"
  sudo cp "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" "$TARGET_DIRs/certs/key.pem"
fi
# make data directory
sudo mkdir -p /opt/$(date +%m.%d)/data

echo "Setup complete."
