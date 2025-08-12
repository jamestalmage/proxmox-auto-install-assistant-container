ARG BASE_IMAGE=debian:trixie-slim
FROM --platform=linux/amd64 $BASE_IMAGE

# Update CA certificates (wget was failing on Lets Encrypt certs without this)
RUN <<EOF
set -eu
apt-get update -y
apt-get install -y --no-install-recommends \
          wget \
          ca-certificates \
          mkisofs \
          squashfs-tools \
          fakeroot \
          xorriso
apt-get remove -y ca-certificates
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Install the proxmox-auto-install-assistant
RUN <<EOF
set -eu
. /etc/os-release
wget "https://enterprise.proxmox.com/debian/proxmox-release-${VERSION_CODENAME}.gpg" \
      -O "/etc/apt/trusted.gpg.d/proxmox-release-${VERSION_CODENAME}.gpg"
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve ${VERSION_CODENAME} pve-no-subscription" > \
      /etc/apt/sources.list.d/pve-install-repo.list
apt-get update -y
apt-get install -y --no-install-recommends \
        proxmox-auto-install-assistant
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

COPY ./assistant/ /assistant/

RUN chmod +x /assistant/*.sh

RUN <<EOF
set -eu
mv $(which proxmox-auto-install-assistant) /usr/bin/original-proxmox-auto-install-assistant
ln -s /assistant/assistant-wrapper.sh /usr/bin/
ln -s /assistant/mod-dhcp.sh /usr/bin/
mv /usr/bin/assistant-wrapper.sh /usr/bin/proxmox-auto-install-assistant
mv /usr/bin/mod-dhcp.sh /usr/bin/mod-proxmox-dhcp
EOF

ENTRYPOINT ["/assistant/docker-entrypoint.sh"]

LABEL maintainer="James Talmage <james@talmage.io>"
LABEL org.opencontainers.image.source=https://github.com/jamestalmage/proxmox-auto-install-assistant-container
LABEL org.opencontainers.image.description="Create automated installations of proxmox, test and validate answer files."
LABEL org.opencontainers.image.licenses=MIT
