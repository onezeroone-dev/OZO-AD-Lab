#!/bin/bash

# Fail if the source ISO does not exist
if [[ ! -f /mnt/c/ozo-ad-lab/ISO/AlmaLinux-9.5-x86_64-boot.iso ]]
then
    exit 1
fi

# Passed all checks; install required packages
apt-get -qq -y install genisoimage isomd5sum rsync syslinux syslinux-common syslinux-efi syslinux-utils
# Make sure we are in the root user home directory
cd ~
# Create a directory for mounting the ISO if it does not exit
if [[ ! -d ~/mnt ]]
then
    mkdir ~/mnt
fi
# Create a target directory for copying the ISO contents if it does not exist; or otherwise empty it
if [[ ! -d ~/ozo-ad-lab-router ]]
then
    mkdir ~/ozo-ad-lab-router
else
    rm -rf ~/ozo-ad-lab-router/*
fi
# Mount the ISO
mount -o loop /mnt/c/ozo-ad-lab/ISO/AlmaLinux-9.5-x86_64-boot.iso ~/mnt/
# Copy the contents
rsync -av ~/mnt/ ~/ozo-ad-lab-router/
# Unmount the ISO
umount ~/mnt
#### Copy in the Kickstart
#### Modify the ISOLinux and Grub boot menu entries
# Create the modified ISO
mkisofs -o /mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso -b isolinux/isolinux.bin -J -R -l -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -graft-points -V AlmaLinux-9-5-x86_64-dvd ~/ozo-ad-lab-router/
# Make the ISO writable to USB
isohybrid --uefi /mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso
# Embed the MD5SUM
implantisomd5 /mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso
# Clean up
rm -rf ~/mnt
rm -rf ~/ozo-ad-lab-router

# Determine if modified ISO exists
if [[ -f /mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso ]]
then
    exit 0
else
    exit 1
fi

# >/dev/null 2>&1
# wsl --distribution "Debian" --user root SOURCE_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/AlmaLinux-9.5-x86_64-boot.iso" TARGET_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso" TARGET_ISO_LABEL="AlmaLinux-9-5-x86_64-dvd" /mnt/c/ozo-ad-lab/Linux/ozo-create-router-iso.sh
# wsl --distribution "Debian" --user root /mnt/c/ozo-ad-lab/Linux/ozo-create-router-iso-test.sh
