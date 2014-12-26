[Bash]FTP Backup Script
======================

A small script to upload backup tar to an external FTP server

How it works:
* You need to change "USERNAME,PASSWORD,SERVER" whit information of your server
* You need to change "DIR" whit absolute position of folder/file you want backup
* You need to change "FILE" whit results of compression

If you have some problem open an issues on GitHub

FAQ:

* >Q: How can i make backup automatic?
* A: You can use crontab (on linux)

* >Q: Why i can't start script?
* A: Try change file permission

* >Q: Work on all linux distro?
* A: This script was tested on Ubuntu 12/14,Debian and Centos 6 and work whitout problem