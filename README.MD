[Bash]FTP Backup Script
======================

A small script to upload backup tar to an external FTP server

How it works:
* You need to change "USERNAME,PASSWORD,SERVER" whit information of your server
* You need to change "DIR" whit absolute position of folder/file you want backup
* You need to change "FILE" whit results of compression

If you have some problem open an issues on GitHub

##FAQ;

* Q: How can I make backups automatic?

    A: You can use crontab (on linux) [link](http://www.cyberciti.biz/faq/how-do-i-add-jobs-to-cron-under-linux-or-unix-oses/)


* Q: Why can't I start the script?

    A: Make the file executable (chmod -x script.sh)


* Q: Will this work on all linux distros?

    A: This script was tested on Ubuntu 12/14,Debian and Centos 6 and has worked whitout any problems
	
* Q: Why SFTP don't work?

    A: You need to install "sshpass" ( apt-get install sshpass )