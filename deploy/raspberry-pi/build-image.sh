#!/usr/bin/env bash
# Build a bootable Raspberry Pi image containing A Book Of Life To Rebuild
# The World, fully offline.
#
# Requirements (on the build host):
#   - Debian/Ubuntu with: apt-get install -y qemu-user-static binfmt-support \
#     kpartx dosfstools e2fsprogs wget xz-utils
#   - sudo access
#   - ~6 GB free disk

set -euo pipefail

# --- Configuration -----------------------------------------------------------
REPO_URL="${REPO_URL:-https://github.com/abookoflife/a-book-of-life-to-rebuild-the-world.git}"
IMAGE_NAME="${IMAGE_NAME:-a-book-of-life}"
IMAGE_SIZE="${IMAGE_SIZE:-4G}"
BUILD_DIR="${BUILD_DIR:-$(pwd)/pi-build}"
BASE_IMAGE_URL="${BASE_IMAGE_URL:-https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-lite-arm64.img.xz}"
BASE_IMAGE_XZ="${BUILD_DIR}/base.img.xz"
BASE_IMAGE="${BUILD_DIR}/base.img"
WORK_IMAGE="${BUILD_DIR}/${IMAGE_NAME}.img"
MOUNT_DIR="${BUILD_DIR}/mnt"

# --- Helpers -----------------------------------------------------------------
log() { printf "\033[1;34m[build]\033[0m %s\n" "$*"; }
die() { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; exit 1; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "Run as root (use sudo)."
  fi
}

cleanup() {
  set +e
  if mountpoint -q "${MOUNT_DIR}/boot"; then umount "${MOUNT_DIR}/boot"; fi
  if mountpoint -q "${MOUNT_DIR}"; then umount "${MOUNT_DIR}"; fi
  if [ -n "${LOOP_DEV:-}" ]; then losetup -d "${LOOP_DEV}" 2>/dev/null; fi
  set -e
}
trap cleanup EXIT

# --- Main --------------------------------------------------------------------
mkdir -p "${BUILD_DIR}" "${MOUNT_DIR}"

if [ ! -f "${BASE_IMAGE_XZ}" ]; then
  log "Downloading base Raspberry Pi OS Lite image..."
  wget -O "${BASE_IMAGE_XZ}" "${BASE_IMAGE_URL}"
fi

if [ ! -f "${BASE_IMAGE}" ]; then
  log "Decompressing base image..."
  xz -dk "${BASE_IMAGE_XZ}" -c > "${BASE_IMAGE}"
fi

log "Creating working image (${IMAGE_SIZE})..."
cp "${BASE_IMAGE}" "${WORK_IMAGE}"
truncate -s "${IMAGE_SIZE}" "${WORK_IMAGE}"

log "Expanding root partition..."
# Grow the last partition to fill the image.
parted -s "${WORK_IMAGE}" resizepart 2 100%

log "Attaching loop device..."
LOOP_DEV=$(losetup --find --show --partscan "${WORK_IMAGE}")
log "  loop: ${LOOP_DEV}"

log "Checking filesystems..."
e2fsck -fy "${LOOP_DEV}p2" || true
resize2fs "${LOOP_DEV}p2"

log "Mounting..."
mount "${LOOP_DEV}p2" "${MOUNT_DIR}"
mount "${LOOP_DEV}p1" "${MOUNT_DIR}/boot"

log "Enabling SSH and Wi-Fi defaults..."
touch "${MOUNT_DIR}/boot/ssh"

# Enable QEMU ARM emulation for first-boot chroot
if [ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  log "Registering qemu-aarch64 binfmt..."
  apt-get install -y qemu-user-static binfmt-support
fi

log "Copying QEMU static binary into chroot..."
cp /usr/bin/qemu-aarch64-static "${MOUNT_DIR}/usr/bin/"

log "Writing first-boot provisioning script..."
cat > "${MOUNT_DIR}/usr/local/sbin/abook-provision.sh" <<'PROVISION'
#!/usr/bin/env bash
set -euo pipefail

REPO_URL="__REPO_URL__"
INSTALL_DIR="/opt/a-book-of-life"

echo "[provision] Installing A Book Of Life To Rebuild The World..."

apt-get update
apt-get install -y \
  python3 python3-pip python3-venv git \
  docker.io docker-compose-plugin \
  avahi-daemon

systemctl enable avahi-daemon

if [ ! -d "${INSTALL_DIR}" ]; then
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

cd "${INSTALL_DIR}"
python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

python scripts/validate.py
python scripts/build_index.py
python scripts/build_zim.py || true

# Build the Docker stack on first boot (may take 30+ minutes)
systemctl enable docker
docker compose -f deploy/docker/docker-compose.yml pull || true
docker compose -f deploy/docker/docker-compose.yml up -d || true

# Systemd unit for the API server (fallback if Docker unavailable)
cat > /etc/systemd/system/abook.service <<'UNIT'
[Unit]
Description=A Book Of Life To Rebuild The World — API
After=network-online.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/a-book-of-life
ExecStart=/opt/a-book-of-life/.venv/bin/python scripts/serve.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable abook.service
systemctl start abook.service

# Advertise on the LAN
cat > /etc/avahi/services/abook.service <<'AVAHI'
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name>A Book Of Life</name>
  <service>
    <type>_http._tcp</type>
    <port>8080</port>
  </service>
</service-group>
AVAHI

systemctl restart avahi-daemon

echo "[provision] Done. Connect to http://$(hostname -I | awk '{print $1}'):8080"
PROVISION

sed -i "s|__REPO_URL__|${REPO_URL}|" "${MOUNT_DIR}/usr/local/sbin/abook-provision.sh"
chmod +x "${MOUNT_DIR}/usr/local/sbin/abook-provision.sh"

log "Registering first-boot service..."
cat > "${MOUNT_DIR}/etc/systemd/system/abook-provision.service" <<'UNIT'
[Unit]
Description=Provision A Book Of Life To Rebuild The World
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/abook-provision.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

ln -sf /etc/systemd/system/abook-provision.service \
  "${MOUNT_DIR}/etc/systemd/system/multi-user.target.wants/abook-provision.service"

log "Cleaning up chroot artifacts..."
rm -f "${MOUNT_DIR}/usr/bin/qemu-aarch64-static"

log "Unmounting..."
sync
umount "${MOUNT_DIR}/boot"
umount "${MOUNT_DIR}"
losetup -d "${LOOP_DEV}"
unset LOOP_DEV

log "Compressing final image..."
xz -T0 -9 "${WORK_IMAGE}"

log "Done: ${WORK_IMAGE}.xz"
log "Flash with:"
log "  xz -dc ${WORK_IMAGE}.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync"
