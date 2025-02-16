[jamestalmage/proxmox-auto-install-assistant](https://github.com/jamestalmage/proxmox-auto-install-assistant-container) 
--------------------------------------------

Provides a Debian base image with [proxmox-auto-install-assistant](https://pve.proxmox.com/wiki/Automated_Installation#Assistant_Tool) installed.

The resulting image also has a few utilities installed that are useful for working with proxmox iso images:
  `wget`, `xorriso`, `mkisofs`, `squashfs-tools`, `fakeroot`

The original binary is wrapped with a script that adds a `--mod-dhcp` flag. The flag is only applicable to the `prepare-iso` command. When that flag is used the script will modify the proxmox iso image to increase the dhcp timeout to 60 seconds. This is useful when using the proxmox iso in a PXE environment.

You can also execute the DHCP modification as a separate step. Just run the `prepare-iso` command as normal (remove the `--mod-dhcp` flag) and then call:

`mod-proxmox-dhcp ${ISO_GENERATED_BY_FIRST_STEP} ${OUTPUT_ISO_PATH}`

**NOTE:** If for some reason you think the wrapper is the source of an issue the original binary is available as `original-auto-install-assistant`. If using that directly fixes a build that otherwise breaks, please submit a bug report.

# Usage

## Launch an interactive shell

You can load an interactive shell to modify manually. You will want to bind-mount a folder that has your iso's in it. (i.e. the same directory the [netboot.xyz container](https://netboot.xyz/docs/docker/parameters) `/assets` folder is bound to).
```shell
docker container run -it -v ${HOST_PATH_TO_NETBOOTXYZ}:/isos jamestalmage/proxmox-auto-install-assistant bash
```

##### Prepare an ISO (in shell using wrapped binary)

Use the `--mod-dhcp` flag to increase the dhcp timeout to 60 seconds.

```shell
proxmox-auto-install-assistant prepare-iso --fetch-from http "proxmox.iso" --url http://example.org/answerfile --mod-dhcp
```

##### Modify an ISO (in shell using separate steps)

This is useful if you think the wrapper is what is causing issues 

```shell
# The first step emits a file called proxmox-1.iso
original-auto-install-assistant prepare-iso --fetch-from http "proxmox.iso" --output "proxmox-1.iso" --url http://example.org/answerfile

# The second step modifies the dhcp timeout
mod-proxmox-dhcp proxmox-1.iso proxmox-2.iso
```

## Use as the base for your own image

```dockerfile
FROM jamestalmage/proxmox-auto-install-assistant

ENV PROXMOX_VERSION=8.3-1

RUN wget "http://download.proxmox.com/iso/proxmox-ve_${PROXMOX_VERSION}.iso"

RUN proxmox-auto-install-assistant prepare-iso --mod-dhcp --fetch-from http "proxmox-ve_${PROXMOX_VERSION}.iso" --url http://example.org/answerfile/proxmox

## Do stuff with the iso, serve it, export it, whatever
```