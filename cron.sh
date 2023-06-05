#!/bin/bash

# ajouter le travail de cron
(crontab -l ; echo "00 * * * 5 /root/backup_script.sh") | crontab -

# démarrer le service cron
cron -f

