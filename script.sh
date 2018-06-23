#!/usr/bin/env bash

# Linux Simple Backup Script

#
# Configuration
#

# Backup Information
FILE="BACKUP_NAME" #Filename of backup file to be transfered (string)
EXT="zip" # Possbile value: zip,tar (string)
DIR="/var/www" #Directory where thing to backup is located (string)
EXCLUSION=("/var/www/**/node_modules /var/www/**/vendor") #Directory to exclude (array space separeted)
CHECKSUM=true #Generate backup checksum (true|false)
ROTATION=30	  #How many day keep (int|false)	

# Encryption Information
ENCRYPTION=false #Encryption (true|false)
ENCRYPTION_RANDOM=false #Random key generation (true|false) (Require notification enable)
ENCRYPTION_KEY="./my_super_secret_backup.key" #Encryption key (absolute path to file with key)

#Notifications information
NOTIFICATION=false #Notifications (true|false)

#Notifications Type
#1= Telegram Bot
#2= Email
NOTIFICATION_TYPE=(1) #Multiple notifications support (array space separeted)

TELEGRAM_KEY="YOUR_TELEGRAM_BOT_KEY" #Multiple notifications support (string)
TELEGRAM_CHAT=(1) #Multiple recipient support (array space separeted)

SMTP_IP="IP HERE" #SMTP Server IP (string)
SMTP_PORT=465 #SMTP Server Port (int)
SMTP_AUTH_USER="" #SMTP User (string)
SMTP_AUTH_PASSWORD="" #SMTP Password (string)
SMTP_FROM="my_backup_script@my_server" #From email (string)
SMTP_TO=("me@my_email") #Multiple recipient support (array space separeted)

#Transfer type
#1=FTP
#2=SFTP
#3=Megatools
#4=Rclone
TYPE=(1 2 3 4) #Multiple destinations support (array space separeted)

# (S)FTP Login Data
USERNAME="USERNAME HERE" #Login username (string)
PASSWORD="PASSWORD HERE" #Login password (string)
SERVER="IP HERE" #Remote server address (string)
PORT="REMOTE SERVER PORT" #Remote server port (string)
REMOTEDIR="./" #Remote server port (string)

# Megatools Configuration
MEGATOOLS_PATH="/usr/local/bin"  #Megatools binary folder (string)
MEGA_DESTIONATION="/Root/MY_BACKUP_FOLDER" #Mega folder (string)

# RClone Configuration
RCLONE_PATH="/usr/local/bin"  #RClone binary folder (string)
RCLONE_REMOTE=("/Root/MY_BACKUP_FOLDER") #Rclone destinations (array space separeted)

# Task Configuration
BEFORE_COMMAND=false #Command to run before backup start (string|false)
AFTER_COMMAND=false #Command to run after backup finish (string|false)


#
# Functions
#

check_configuration() { #TODO
	
}

generate_file_name() { #TODO
	d=$(date '+%Y-%m-%d_%H')
	FILE="$FILE""_$d.tar.gz"
}

generate_key(){
	$KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

read_key(){ #TODO
	
}

generate_backup_command(){
	tar -czvf "./$FILE" "$DIR"
	echo 'Tar Complete'
}

ftp_upload(){
	ftp -n -i "$SERVER" "$PORT" <<EOF
	user "$USERNAME" "$PASSWORD"
	binary
	put "$FILE" "$REMOTEDIR"/"$FILE"
	quit
EOF
}

ftp_rotation(){ #TODO

}

sftp_upload(){
	rsync --rsh="sshpass -p \"$PASSWORD\" ssh -p \"$PORT\" -o StrictHostKeyChecking=no -l \"$USERNAME\"" "$FILE" "$SERVER":"$REMOTEDIR"
}

sftp_rotation(){ #TODO

}

mega_upload(){ #TODO
	
}

mega_rotation(){ #TODO
	
}

rclone_upload($rclone_destination){ #TODO
	
}

rclone_rotation($rclone_destination){ #TODO
	
}

generate_checksum(){ #TODO
	
}

telegram_notification(){
	curl -s -X POST https://api.telegram.org/bot$apiToken/sendMessage -F document=@"LOG_FILE" -F caption="Text Message with attachment" -d chat_id=$chatId #TODO
}

smtp_notification(){
	mailx -a file.txt -s "Subject" user@domain.com < /dev/null #TODO
}

clean_backup() {
	rm -f "./$FILE"
	echo 'Local Backup Removed'
}

#
# Here be dragons
#

check_configuration

if [ "$BEFORE_COMMAND" != false ]
then
	$($BEFORE_COMMAND)
fi

generate_file_name

if [ "$ENCRYPTION" = true ] && [ "$ENCRYPTION_RANDOM" = true ]
then
	generate_key
elif [ "$ENCRYPTION" = true ]
then
	read_key
fi
	
generate_backup_command

for operation in "${TYPE[@]}"
do
	if [ "$operation" -eq 1 ]
	then
		ftp_upload()
		if [ "$ROTATION" != false ]
			ftp_rotation
		fi
	elif [ "$operation" -eq 2 ]
	then
		sftp_upload()
		if [ "$ROTATION" != false ]
			sftp_rotation
		fi
	elif [ "$operation" -eq 3 ]
	then
		mega_upload()
		if [ "$ROTATION" != false ]
			mega_rotation
		fi
	elif [ "$operation" -eq 4 ]
	then
		for rclone_destination in "${RCLONE_REMOTE[@]}"
		do
			rclone_upload "$rclone_destination"
			if [ "$ROTATION" != false ]
				rclone_rotation
			fi
		done
	else
		echo 'Invalid backup type option'
	fi
done

if [ "$CHECKSUM" = true ]
	generate_checksum
fi

if [ "$NOTIFICATION" = true ]
then
	for notification_operation in "${NOTIFICATION_TYPE[@]}"
	do
		if [ "$notification_operation" -eq 1 ]
		then
			telegram_notification()
		elif [ "$notification_operation" -eq 2 ]
		then
			smtp_notification()
		fi
	done
fi

echo 'Remote Backup Complete'
clean_backup

if [ "$AFTER_COMMAND" != false ]
then
	$($AFTER_COMMAND)
fi

#END
