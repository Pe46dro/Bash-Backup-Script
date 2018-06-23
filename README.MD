
# [Bash]FTP Backup Script
[![Build Status](https://travis-ci.org/Pe46dro/Bash-FTP-Backup-Script.svg?branch=master)](https://travis-ci.org/Pe46dro/Bash-FTP-Backup-Script) [![Beerpay](https://img.shields.io/beerpay/hashdog/scrapfy-chrome-extension.svg)](https://beerpay.io/Pe46dro/Bash-FTP-Backup-Script)
A small script to backup a compressed folder to an external storage

### Prerequisites
Here you find the software that you need to install to have the function working
* cURL (Telegram notifications)
* mailx  (Email notifications)
* Rclone  (Rclone  backup)
* Megatools  (Mega.co.nz backup)
* sshpass  (SFTP backup)

## How it works:
* Clone the repository `git clone https://github.com/Pe46dro/Bash-FTP-Backup-Script.git` or download script.sh `wget https://github.com/Pe46dro/Bash-FTP-Backup-Script/blob/master/script.sh` 
* Open script.sh with your favorite text editor `vim script.sh`
* Customize the configuration and save
* Run `bash script.sh`

If you have some problem open an issues on GitHub

## FAQ

* Q: How can I make backups automatic?
    A: Yes, you can use [crontab](http://www.cyberciti.biz/faq/how-do-i-add-jobs-to-cron-under-linux-or-unix-oses/)

* Q: Will this work on all linux distros?
    A: This script was tested on Ubuntu (12/14),Debian (8/9) and Centos 6 and has worked whitout any problems
	
* Q: Why SFTP don't work?
    A: You need to install "sshpass" ( apt-get install sshpass )
    
* Q: Can i backup my MySQL database?
    A: Check my script for my [MySQL backup](https://github.com/Pe46dro/Bash-MySQL-Database-SFTP-FTP-Backup)

# Contributors
| [<img src="https://www.gravatar.com/avatar/35923b3b04e23bef801553656b606bfag?s=100" alt="" height="100">](https://github.com/Pe46dro) |
|--|
| [Pe46dro](https://github.com/Pe46dro) |


## License

This project is licensed under the GNU General Public License v3.0 License - see the [LICENSE.md](LICENSE.md) file for details