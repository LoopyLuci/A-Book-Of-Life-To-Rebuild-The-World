#!/usr/bin/env bash
# Install A Book Of Life To Rebuild The World on an existing Raspberry Pi.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World.git}"
INSTALL_DIR="${INSTALL_DIR:-/opt/a-book-of-life}"

echo "Installing A Book Of Life To Rebuild The World to ${INSTALL_DIR}..."

sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv git docker.io docker-compose-plugin

if [ ! -d "${INSTALL_DIR}" ]; then
  sudo git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

cd "${INSTALL_DIR}"

python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

python scripts/validate.py
python scripts/build_index.py
python scripts/build_zim.py || true

sudo cp deploy/raspberry-pi/abook.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable abook
sudo systemctl start abook

echo "A Book Of Life is running at http://$(hostname -I | awk '{print $1}'):8080"
