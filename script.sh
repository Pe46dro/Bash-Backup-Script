#!/usr/bin/env bash

# Linux Simple Backup Script

#
# Configuration
#

# Backup Information
FILE="BACKUP_NAME" #Filename of backup file to be transfered (string)
EXT="zip" #Possbile value: zip,tar (string)
DIR="/var/www" #Directory where thing to backup is located (string)
EXCLUSION=("/var/www/**/node_modules" "/var/www/**/vendor") #Directory to exclude (array space separeted)
CHECKSUM=true #Generate backup checksum (true|false)
ROTATION=30	#How many day keep for better rotation use RClone (int|false)
LOG_FILE="/dev/null" #Log file location (string|/dev/null)
TMP_FOLDER="/tmp/" #Temp folder for archive generation

#Encryption Information (only zip)
ENCRYPTION=false #Encryption (true|false)
ENCRYPTION_RANDOM=false #Random key generation (true|false) (Require notification enable)
ENCRYPTION_KEY="./my_super_secret_backup.key" #Encryption key (absolute path to file with key)

#Notifications information
NOTIFICATION=false #Notifications (true|false)
SEND_LOG=false #Send log file (true|false)

#Notifications Type
#1= Telegram Bot
#2= FUTURE USE
NOTIFICATION_TYPE=(1) #Multiple notifications support (array space separeted)

TELEGRAM_KEY="YOUR_TELEGRAM_BOT_KEY" #Multiple notifications support (string)
TELEGRAM_CHAT=(1) #Multiple recipient support (array space separeted)

#Transfer type
#1=FTP
#2=Rclone https://rclone.org/
TYPE=(1 2) #Multiple destinations support (array space separeted)

# FTP(s) Login Data
USERNAME="USERNAME HERE" #Login username (string)
PASSWORD="PASSWORD HERE" #Login password (string)
SERVER="IP HERE" #Remote server address (string)
PORT="REMOTE SERVER PORT" #Remote server port (string)
REMOTEDIR="./" #Remote server port (string)

# RClone Configuration
RCLONE_PATH="/usr/local/bin"  #RClone binary folder (string)
RCLONE_REMOTE=("DEST1:/" "DEST2:/") #Rclone destinations (array space separeted)

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
		exit 1
		fi
		
		if [ "$(stat -c %A "$ENCRYPTION_KEY")" != "-rw-------" ]
		then
			echo "WARNING: UNPROTECTED PRIVATE KEY FILE!" | tee -a --output-error=warn "$LOG_FILE"
       			echo "Permissions for '$ENCRYPTION_KEY' are too open. It is recommended that your private key files are NOT accessible by others." | tee -a --output-error=warn "$LOG_FILE"
		exit 1
		fi
		
	fi
	if [ "$ENCRYPTION" = true ] && [ "$ENCRYPTION_RANDOM" = true ] && [ "$NOTIFICATION" = false ]
	then
		echo "Random key require notification" | tee -a --output-error=warn "$LOG_FILE"
	fi
}

generate_file_name() {
	if [ "$ROTATION" != false ]
	then
		d=$(date --date="-$ROTATION day" '+%Y-%m-%d_%H')
		RFILE="$FILE""_$d.$EXT"
	fi
	d=$(date '+%Y-%m-%d_%H')
	FILE="$FILE""_$d.$EXT"
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

                if [ "$ENCRYPTION" = true ] && [ "$NOTIFICATION" = true ]
                then
                        PARAMS="-P $KEY"
                fi

                for EXL in "${EXCLUSION[@]}"
                do
                        echo "Excluding '$EXL'"
                        PARAMS="$PARAMS --exclude '$EXL'"
                done

                PARAMS="$PARAMS -r $TMP_FOLDER$FILE $DIR"

                local CMD="zip $PARAMS"

                eval "$CMD" | tee -a "$LOG_FILE"
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

rclone_upload () {
	# $1 RClone remote
	"$RCLONE_PATH"/rclone copy "$TMP_FOLDER$FILE" "$1"
	
}

rclone_rotation () {
	# $1 RClone remote
	"$RCLONE_PATH"/rclone delete "$1" --min-age "$ROTATION"d
}

generate_checksum(){
	echo "MD5 HASH"
	md5sum "$TMP_FOLDER$FILE" | tee -a "$LOG_FILE"
}

telegram_notification(){
	# $1 Chat id
	if [ "$SEND_LOG" = true ]
	then
	curl -F chat_id="$1" -F document=@"$LOG_FILE" https://api.telegram.org/bot"$TELEGRAM_KEY"/sendDocument
	fi
	
	if [ "$ENCRYPTION" = true ] && [ "$ENCRYPTION_RANDOM" = true ]
	then
		curl -s -X POST https://api.telegram.org/bot"$TELEGRAM_KEY"/sendMessage -d chat_id="$1" -d text="Key: $KEY"
        fi
}

clean_backup() {
	rm -f "$TMP_FOLDER$FILE"
	echo 'Local Backup Removed' | tee -a "$LOG_FILE"
}

#
# Here be dragons
#

check_configuration

echo "###########################################"  | tee -a "$LOG_FILE"
echo "Starting backup $FILE"  | tee -a "$LOG_FILE"
echo "###########################################"  | tee -a "$LOG_FILE"

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
		for rclone_destination in "${RCLONE_REMOTE[@]}"
		do
			rclone_upload "$rclone_destination"
			if [ "$ROTATION" != false ]
			then
				rclone_rotation "$rclone_destination"
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

echo "###########################################"  | tee -a "$LOG_FILE"
echo "Ending backup $FILE"  | tee -a "$LOG_FILE"
echo "###########################################"  | tee -a "$LOG_FILE"

#END
