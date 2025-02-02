FROM debian:12.9-slim

# Update CA certificates (wget was failing on Lets Encrypt certs without this)
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
          wget \
          ca-certificates \
    && update-ca-certificates

# Install the proxmox-auto-install-assistant
RUN . /etc/os-release \
    && wget "https://enterprise.proxmox.com/debian/proxmox-release-${VERSION_CODENAME}.gpg" \
      -O "/etc/apt/trusted.gpg.d/proxmox-release-${VERSION_CODENAME}.gpg" \
    && echo "deb [arch=amd64] http://download.proxmox.com/debian/pve ${VERSION_CODENAME} pve-no-subscription" > \
        /etc/apt/sources.list.d/pve-install-repo.list \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends  \
        proxmox-auto-install-assistant \
        xorriso

LABEL maintainer="James Talmage <james@talmage.io>"
LABEL org.opencontainers.image.source=https://github.com/jamestalmage/proxmox-auto-install-assistant-container
LABEL org.opencontainers.image.description="Create automated installations of proxmox, test and validate answer files."
LABEL org.opencontainers.image.licenses=MIT
