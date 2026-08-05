#!/bin/bash

#SOURCE_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/almalinux-boot.iso"
#TARGET_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso"
#TARGET_ISO_LABEL="OZO-AD-Lab-Router"

# wsl --distribution "Debian" --user root GRUB_PATH="/mnt/c/ozo-ad-lab/Linux/ozo-ad-lab-grub.cfg" KICKSTART_PATH="/mnt/c/ozo-ad-lab/Linux/ozo-ad-lab-router-ks.cfg" SOURCE_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/almalinux-boot.iso" TARGET_ISO_PATH="/mnt/c/ozo-ad-lab/ISO/OZO-AD-Lab-Router.iso" TARGET_ISO_LABEL="OZO-AD-Lab-Router" /mnt/c/ozo-ad-lab/Linux/ozo-create-router-iso.sh

# Local variables
OZO_AD_LAB_PATH=~/ozo-ad-lab
MNT_PATH=$OZO_AD_LAB_PATH/mnt
COPY_PATH=$OZO_AD_LAB_PATH/router

# Fail if the Grub configuration does not exist
if [[ ! -f $GRUB_PATH ]]
then
    echo "Grub configuration file not found."
    exit 0
fi

# Fail if the Kickstart does not exist
if [[ ! -f $KICKSTART_PATH ]]
then
    echo "Kickstart file not found."
    exit 0
fi

# Fail if the source ISO does not exist
if [[ ! -f $SOURCE_ISO_PATH ]]
then
    echo "Source ISO path is not set."
    exit 0
fi

# Fail if target ISO path is not set
if [[ $TARGET_ISO_PATH = "" ]]
then
    echo "Target ISO path is not set."
    exit 0
fi

# Fail if target ISO label is not set
if [[ $TARGET_ISO_LABEL = "" ]]
then
    echo "Target ISO label is not set."
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
# Copy in the Kickstart
cp $KICKSTART_PATH $COPY_PATH/ks.cfg
# Copy in Grub configuration
cp -f $GRUB_PATH $COPY_PATH/boot/grub2/grub.cfg
# Create the modified ISO
# mkisofs -input-charset utf-8 -b isolinux/isolinux.bin -J -R -l -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -graft-points -V $TARGET_ISO_LABEL -o $TARGET_ISO_PATH $COPY_PATH/ >/dev/null 2>&1
mkisofs -input-charset utf-8 -J -l -R -iso-level 3 -udf -e boot/grub2/i386-pc/boot.img -no-emul-boot -V $TARGET_ISO_LABEL -o $TARGET_ISO_PATH $COPY_PATH/
# >/dev/null 2>&1
# Make the ISO writable to USB
isohybrid --uefi $TARGET_ISO_PATH
# >/dev/null 2>&1
# Embed the MD5SUM
implantisomd5 $TARGET_ISO_PATH
# >/dev/null 2>&1
# Clean up
rm -rf $OZO_AD_LAB_PATH >/dev/null 2>&1

# Determine if modified ISO exists
if [[ -f $TARGET_ISO_PATH ]]
then
    echo "TRUE"
else
    echo "FALSE"
fi
