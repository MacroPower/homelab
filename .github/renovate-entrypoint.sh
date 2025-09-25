#!/bin/bash

groupadd -r nixbld

mkdir -m 0755 /nix
chown -R ubuntu:ubuntu /nix

for n in $(seq 1 10); do
  useradd -c "Nix build user $n" -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(command -v nologin)" "nixbld$n"
done

echo "Installing nix"
su ubuntu <<'EOF'
  bash <(curl -L https://nixos.org/nix/install) --no-daemon
  chmod +x ~/.nix-profile/etc/profile.d/nix.sh
  ~/.nix-profile/etc/profile.d/nix.sh
EOF
chown -R ubuntu:ubuntu /nix

export DEVBOX_USE_VERSION="0.13.7"
export DEVBOX_USER="ubuntu"
export PATH="/home/${DEVBOX_USER}/.nix-profile/bin:$PATH"

echo "Installing devbox"
curl -L https://get.jetify.com/devbox | bash -s -- -f
chown -R ubuntu:ubuntu /usr/local/bin/devbox
chmod +x /usr/local/bin/devbox

KCLIPPER_URL=$(curl -s "https://api.github.com/repos/macropower/kclipper/releases/latest" | \
  jq -r ".assets[] | select(.name | test(\"kclipper_$(uname)_$(arch).tar.gz\")) | .browser_download_url")

echo "Downloading kclipper from $KCLIPPER_URL"
curl -L $KCLIPPER_URL | tar -zx

chmod +x kcl
mv kcl /usr/local/bin

runuser -u ubuntu renovate
