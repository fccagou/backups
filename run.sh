#!/bin/bash -ue

# The udev rule is not terribly accurate and may trigger our service before
# the kernel has finished probing partitions. Sleep for a bit to ensure
# the kernel is done.
#
# This can be avoided by using a more precise udev rule, e.g. matching
# a specific hardware path and partition.
sleep 5

#
# Script configuration
#

PREFIX=${PREFIX:-/srv/backups}


# Archive name schema
DATE=$(date --iso-8601)-$(hostname)

# This is the file that will later contain UUIDs of registered backup drives
DISKS=/etc/backups/backup.disks

if [ ! -f ${DISKS} ]
then
    echo -e "[-] conf file not found (${DISKS}) ... exiting ...\n"
    exit 1
fi

# Find whether the connected block device is a backup drive
for uuid in $(lsblk --noheadings --list --output uuid)
do
        if grep --quiet --fixed-strings $uuid $DISKS; then
                break
        fi
        uuid=
done

if [ ! $uuid ]; then
        echo "No backup disk found, exiting"
        exit 0
fi

echo "Disk $uuid is a backup disk"
# The backup partition is mounted there
MOUNTPOINT=${PREFIX}/mnt/$uuid
BACKUPCMD="/etc/backups/backup-${uuid}"

[ ! -d ${MOUNTPOINT} ] && { mkdir ${MOUNTPOINT} || { echo -e "[-] error creating mount point (${MOUNTPOINT})... exiting...\n" ; exit 1 ; } }

partition_path=/dev/disk/by-uuid/$uuid
# Mount file system if not already done. This assumes that if something is already
# mounted at $MOUNTPOINT, it is the backup drive. It won't find the drive if
# it was mounted somewhere else.
(mount | grep $MOUNTPOINT) || mount $partition_path $MOUNTPOINT
drive=$(lsblk --inverse --noheadings --list --paths --output name $partition_path | head --lines 1)
echo "Drive path: $drive"

if [ ! -x  ${BACKUPCMD} ]
then
    echo -e "[-] no backup cmd (${BACKUPCMD})\n"
else
    echo -e "[*] running ${BACKUPCMD})\n"
    ${BACKUPCMD} ${MOUNTPOINT}
fi 


# ---------------------------------------------------------------------------
# Create backups
#

# # Options for borg create
# BORG_OPTS="--stats --one-file-system --compression lz4 --checkpoint-interval 86400"
# 
# # Set BORG_PASSPHRASE or BORG_PASSCOMMAND somewhere around here, using export,
# # if encryption is used.
# 
# # No one can answer if Borg asks these questions, it is better to just fail quickly
# # instead of hanging.
# export BORG_RELOCATED_REPO_ACCESS_IS_OK=no
# export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no
# 
# # Log Borg version
# borg --version
# 
# echo "Starting backup for $DATE"
# 
# # This is just an example, change it however you see fit
# borg create $BORG_OPTS \
#   --exclude /root/.cache \
#   --exclude /var/cache \
#   --exclude /var/lib/docker/devicemapper \
#   $TARGET::$DATE-$$-system \
#   / /boot
# 
# # /home is often a separate partition / file system.
# # Even if it isn't (add --exclude /home above), it probably makes sense
# # to have /home in a separate archive.
# borg create $BORG_OPTS \
#   --exclude 'sh:/home/*/.cache' \
#   $TARGET::$DATE-$$-home \
#   /home/
# 

# ---------------------------------------------------------------------------
echo "Completed backup for $DATE"

# Just to be completely paranoid
sync

if [ -f /etc/backups/autoeject ]; then
        umount $MOUNTPOINT
        hdparm -Y $drive
fi

if [ -f /etc/backups/backup-suspend ]; then
        systemctl suspend
fi
