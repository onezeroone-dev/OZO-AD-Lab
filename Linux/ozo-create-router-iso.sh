#!/bin/bash

#SOURCE_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/AlmaLinux-9.5-x86_64-boot.iso"
#TARGET_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso"
#TARGET_ISO_LABEL="AlmaLinux-9-5-x86_64-dvd"

# Local variables
OZO_AD_LAB_PATH=~/ozo-ad-lab
MNT_PATH=$OZO_AD_LAB_PATH/mnt
COPY_PATH=$OZO_AD_LAB_PATH/router

# Fail if the source ISO does not exist
if [[ ! -f $SOURCE_ISO_PATH ]]
then
    echo "FALSE"
    exit 0
fi

# Fail if target ISO path is not set
if [[ $TARGET_ISO_PATH = "" ]]
then
    echo "FALSE"
    exit 0
fi

# Fail if target ISO label is not set
if [[ $TARGET_ISO_LABEL = "" ]]
then
    echo "FALSE"
    exit 0
fi

# Passed all checks; install required packages
apt-get -qq -y install genisoimage isomd5sum rsync syslinux syslinux-common syslinux-efi syslinux-utils >/dev/null 2>&1
# Make sure we are in the root user home directory
cd ~
# Create a directory for mounting the ISO if it does not exit
if [[ ! -d $MNT_PATH ]]
then
    mkdir -p $MNT_PATH
fi
# Create a target directory for copying the ISO contents if it does not exist; or otherwise empty it
if [[ ! -d $COPY_PATH ]]
then
    mkdir -p $COPY_PATH
else
    rm -rf $COPY_PATH/*
fi
# Mount the ISO
mount -o loop $SOURCE_ISO_PATH $MNT_PATH/ >/dev/null 2>&1
# Copy the contents
rsync -av $MNT_PATH/ $COPY_PATH/ >/dev/null 2>&1
# Unmount the ISO
umount $MNT_PATH >/dev/null 2>&1
#### Copy in the Kickstart
#### Modify the ISOLinux and Grub boot menu entries
# Create the modified ISO
mkisofs -b isolinux/isolinux.bin -J -R -l -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -graft-points -V $TARGET_ISO_LABEL -o $TARGET_ISO_PATH $COPY_PATH/ >/dev/null 2>&1
# Make the ISO writable to USB
isohybrid --uefi $TARGET_ISO_PATH >/dev/null 2>&1
# Embed the MD5SUM
implantisomd5 $TARGET_ISO_PATH >/dev/null 2>&1
# Clean up
rm -rf $OZO_AD_LAB_PATH >/dev/null 2>&1

# Determine if modified ISO exists
if [[ -f $TARGET_ISO_PATH ]]
then
    echo "TRUE"
else
    echo "FALSE"
fi

# >/dev/null 2>&1
# wsl --distribution "Debian" --user root SOURCE_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/AlmaLinux-9.5-x86_64-boot.iso" TARGET_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso" TARGET_ISO_LABEL="AlmaLinux-9-5-x86_64-dvd" /mnt/c/ozo-ad-lab/Linux/ozo-create-router-iso.sh

