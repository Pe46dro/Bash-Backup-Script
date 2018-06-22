#!/bin/sh

# Linux FTP Backup Script
# Version: 1.0
# Script by: Pietro Marangon
# Skype: pe46dro
# Email: pietro.marangon@gmail.com

clean_backup() {
  rm -f ./$FILE
  echo 'Local Backup Removed'
}

########################
# Edit Below This Line #
########################

# FTP Login Data
USERNAME="USERNAME HERE"
PASSWORD="PASSWORD HERE"
SERVER="IP HERE"
PORT="REMOTE SERVER PORT"

#Directory where thing to backup is located
DIR="/root"

#Remote directory where the backup will be placed
REMOTEDIR="./"

#Filename of backup file to be transfered DON'T WRITE EXTENSION (.tar/.zip/ecc...)
FILE="BACKUP_NAME"

#Transfer type
#1=FTP
#2=SFTP
TYPE=1

##############################
# Don't Edit Below This Line #
##############################

d=$(date --iso)

FILE=$FILE"_"$d".tar.gz"
tar -czvf ./$FILE $DIR
echo 'Tar Complete'

if [ $TYPE -eq 1 ]
then
ftp -n -i $SERVER $PORT <<EOF
user $USERNAME $PASSWORD
binary
put $FILE $REMOTEDIR/$FILE
quit
EOF
elif [ $TYPE -eq 2 ]
then
rsync --rsh="sshpass -p $PASSWORD ssh -p $PORT -o StrictHostKeyChecking=no -l $USERNAME" $FILE $SERVER:$REMOTEDIR
else
echo 'Please select a valid type'
fi

echo 'Remote Backup Complete'
clean_backup
#END
