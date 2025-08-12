#!/bin/bash
# This script is used to modify the Proxmox installer to increase the DHCP timeout
# Before running this script, you need to install the dependencies as follows:
#    apt-get install proxmox-auto-install-assistant mkisofs squashfs-tools xorriso fakeroot
#
# Usage: ./mod-dhcp.sh /path/to/proxmox.iso /path/to/output.iso

# create a temporary file
TEMP_FILE=$(mktemp).iso

#copy into proxmox.mbr the mbr from original iso (first 512byte)
dd if=$1 bs=512 count=1 of=/tmp/proxmox.mbr

#  create temp folders
mkdir /tmp/pve_iso
mkdir /tmp/pve_squash/

# mount iso (iso name and path is given with parameter to script)

osirrox -indev $1 extract / /tmp/pve_iso_tmp
tar cf - -C /tmp/pve_iso_tmp . | tar xfp - -C /tmp/pve_iso
# extract squashfs
fakeroot -- bash -c "
unsquashfs -d /tmp/pve_squash/ /tmp/pve_iso/pve-installer.squashfs
sed -i -e 's/timeout 10;/timeout 60;/g' /tmp/pve_squash/etc/dhcp/dhclient.conf
sed -i -e 's/select-timeout 0;/select-timeout 20;/g' /tmp/pve_squash/etc/dhcp/dhclient.conf
echo \"new dhclient.conf:\"
echo \"\"
cat /tmp/pve_squash/etc/dhcp/dhclient.conf
rm /tmp/pve_iso/pve-installer.squashfs
mksquashfs /tmp/pve_squash/ /tmp/pve_iso/pve-installer.squashfs"

xorriso -as mkisofs \
-o "$TEMP_FILE" \
-r -V 'PVE' \
-isohybrid-mbr /tmp/proxmox.mbr \
-partition_offset 16 \
--protective-msdos-label \
/tmp/pve_iso

echo "Copying the modified iso from temp location to $2"
cp "$TEMP_FILE" "$2"

# # clear up your files
rm -rf /tmp/pve_*
rm /tmp/proxmox.mbr
rm "$TEMP_FILE"
