## Proxmox 

Provides a Debian base image with [proxmox-auto-install-assistant](https://pve.proxmox.com/wiki/Automated_Installation#Assistant_Tool) installed.

The resulting image has wget installed

### Usage

```dockerfile
FROM jamestalmage/proxmox-auto-install-assistant
ENV PROXMOX_VERSION=8.3-1

RUN . /etc/os-release \
    && wget "http://download.proxmox.com/iso/proxmox-ve_${PROXMOX_VERSION}.iso"

RUN proxmox-auto-install-assistant prepare-iso --fetch-from http "proxmox-ve_${PROXMOX_VERSION}.iso" --url http://example.org/answerfile/proxmox
```