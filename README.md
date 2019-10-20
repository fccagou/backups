This is a way ao automates backups on USB disk

Thanks to Borg [1] doc.

# Installation

   cd /srv && git clone https://github.com/fccagou/backups.git && cd backups && mkdir mnt
 
   sudo ln -s /srv/backups/data/40-backup.rules /etc/udev/rules.d/40-backup.rules
   sudo ln -s /srv/backups/data/automatic-backup.service /etc/systemd/system/automatic-backup.service
   sudo systemctl daemon-reload
   sudo udevadm control --reload
   
   sudo mkdir /etc/backups
   sudo touch /etc/backups/backup.disks



# Adding Backup disk

Plug the disk un run 

  lsblk -o+uuid,label

Note the UUID into the /etc/backup/backup.disks file.

Create script /etc/backups/backup-UUID to backup onto this disk
The script takes src and destination dirs as parameters.

You can use tools/* scripts

# References

[1] - https://borgbackup.readthedocs.io/en/stable/deployment/automated-local.html

# TODO

* add conf file


