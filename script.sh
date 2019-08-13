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
LOG_FILE="/var/log/bck_script.log" # Log file location (string)
TMP_FOLDER="/tmp/" #Temp folder for archive generation

# Encryption Information (only zip)
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
#3=Rclone
TYPE=(1 2 3) #Multiple destinations support (array space separeted)

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

check_configuration() {
	if [ "$ENCRYPTION" = true ] && [ "$ENCRYPTION_RANDOM" = false ]
	then
		if [ ! -f "$ENCRYPTION_KEY" ]
		then
			echo "Key file not found!" | tee -a --output-error=warn "$LOG_FILE"
		exit 0
		fi
		
		if [ "$(stat -c %A "$ENCRYPTION_KEY")" != "-rw-------" ]
		then
			echo "WARNING: UNPROTECTED PRIVATE KEY FILE!" | tee -a --output-error=warn "$LOG_FILE"
       			echo "Permissions for '$ENCRYPTION_KEY' are too open. It is recommended that your private key files are NOT accessible by others." | tee -a --output-error=warn "$LOG_FILE"
		exit 0
		fi
		
	fi
}

generate_file_name() {
	d=$(date '+%Y-%m-%d_%H')
	FILE="$FILE""_$d.$EXT"
	
	if [ "$ROTATION" != false ]
	then
		d=$(date --date="-$ROTATION day" '+%Y-%m-%d_%H')
		RFILE="$FILE""_$d.$EXT"
	fi

}

generate_key(){
	KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
}

read_key(){
	KEY=$(cat "$ENCRYPTION_KEY")
}

generate_backup(){

	if [ "$EXT" = "tar" ]
	then
		for EXL in "${EXCLUSION[@]}"
		do
			PARAMS="$PARAMS --exclude='$EXL' "
		done
	
		tar -czvf "$TMP_FOLDER$FILE" "$DIR"  | tee -a "$LOG_FILE"
		echo 'Tar Complete' | tee -a "$LOG_FILE"
	elif [ "$EXT" = "zip" ]
	then
	
		if [ "$ENCRYPTION" = true ]
		then
			PARAMS="--password $KEY "
		fi
	
		for EXL in "${EXCLUSION[@]}"
		do
			PARAMS="$PARAMS --exclude '$EXL'"
		done
	
		zip "$PARAMS" -r "$TMP_FOLDER$FILE" "$DIR"
		echo 'Zip Complete' | tee -a "$LOG_FILE"
	fi
	
}

ftp_upload(){
	ftp -n -i "$SERVER" "$PORT" <<EOF
	user "$USERNAME" "$PASSWORD"
	binary
	put "$TMP_FOLDER$FILE" "$REMOTEDIR"/"$FILE"
	quit
EOF
}

ftp_rotation(){
	ftp -n -i "$SERVER" "$PORT" <<EOF
	user "$USERNAME" "$PASSWORD"
	binary
	cd "$REMOTEDIR"
	delete "$RFILE"
	quit
EOF
}

sftp_upload(){
	rsync --rsh="sshpass -p \"$PASSWORD\" ssh -p \"$PORT\" -o StrictHostKeyChecking=no -l \"$USERNAME\"" "$FILE" "$SERVER":"$REMOTEDIR"
}

sftp_rotation(){ #TODO
	ssh "$USERNAME"@"$SERVER" 'find $REMOTEDIR -type f -mtime +$ROTATION -exec rm {} \;'
	true;
}

rclone_upload () {
	# $1 RClone remote
	"$RCLONE_PATH"/rclone copy "$TMP_FOLDER$FILE" "$1"
	
}

rclone_rotation () {
	# $1 RClone remote
	"$RCLONE_PATH"/rclone delete "$1" --min-age $ROTATIONd
}

generate_checksum(){
	md5sum "$TMP_FOLDER$FILE" | tee -a "$LOG_FILE"
}

telegram_notification(){
	# $1 Chat id
	curl -s -X POST https://api.telegram.org/bot"$TELEGRAM_KEY"/sendMessage -F document=@"$LOG_FILE" -F caption="Backup log" -d chat_id="$1"
}

smtp_notification(){
	 # $1 Email address
	mailx -v -s "Backup completed" \
	-S smtp-use-starttls \
	-S ssl-verify=ignore \
	-S smtp-auth=login \
	-S smtp=smtp://"$SMTP_IP":"$SMTP_PORT" \
	-S from="$SMTP_FROM" \
	-S smtp-auth-user="$SMTP_AUTH_USER" \
	-S smtp-auth-password="$SMTP_AUTH_PASSWORD" \
	-S ssl-verify=ignore \
	-A "$LOG_FILE"
	"$1" | tee -a "$LOG_FILE"
}

clean_backup() {
	rm -f "$TMP_FOLDER$FILE"
	echo 'Local Backup Removed' | tee -a "$LOG_FILE"
}

#
# Here be dragons
#

check_configuration

if [ "$BEFORE_COMMAND" != false ]
then
	# shellcheck disable=SC2091
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
	
generate_backup

for operation in "${TYPE[@]}"
do
	if [ "$operation" -eq 1 ]
	then
		ftp_upload
		if [ "$ROTATION" != false ]
		then
			ftp_rotation
		fi
	elif [ "$operation" -eq 2 ]
	then
		sftp_upload
		if [ "$ROTATION" != false ]
		then
			sftp_rotation
		fi
	elif [ "$operation" -eq 3 ]
	then
		for rclone_destination in "${RCLONE_REMOTE[@]}"
		do
			rclone_upload "$rclone_destination"
			if [ "$ROTATION" != false ]
			then
				rclone_rotation
			fi
		done
	else
		echo "$operation is not a valid backup type option" | tee -a "$LOG_FILE"
	fi
done

if [ "$CHECKSUM" = true ]
then
	generate_checksum
fi

if [ "$NOTIFICATION" = true ]
then
	for notification_operation in "${NOTIFICATION_TYPE[@]}"
	do
		if [ "$notification_operation" -eq 1 ]
		then
			for chat_id in "${TELEGRAM_CHAT[@]}"
			do
				telegram_notification "$chat_id"
			done
		elif [ "$notification_operation" -eq 2 ]
		then
			for email_add in "${SMTP_TO[@]}"
			do
				smtp_notification "$email_add"
			done
		fi
	done
fi

echo 'Remote Backup Complete' | tee -a "$LOG_FILE"
clean_backup

if [ "$AFTER_COMMAND" != false ]
then
	# shellcheck disable=SC2091
	$($AFTER_COMMAND)
fi

#END
