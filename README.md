# [jamestalmage/proxmox-auto-install-assistant](https://github.com/jamestalmage/proxmox-auto-install-assistant-container) 
--------------------------------------------

Provides a Debian base image with [--](https://pve.proxmox.com/wiki/Automated_Installation#Assistant_Tool) installed.

The resulting image has wget installed.

## Usage

### Launch an interactive shell

```shell
docker container run -it -v ${PWD}:/output jamestalmage/proxmox-auto-install-assistant bash
```

### Use as the for your own image

```dockerfile
FROM jamestalmage/proxmox-auto-install-assistant

ENV PROXMOX_VERSION=8.3-1

RUN wget "http://download.proxmox.com/iso/proxmox-ve_${PROXMOX_VERSION}.iso"

RUN proxmox-auto-install-assistant prepare-iso --fetch-from http "proxmox-ve_${PROXMOX_VERSION}.iso" --url http://example.org/answerfile/proxmox

## Do stuff with the iso, serve it, export it, whatever
```