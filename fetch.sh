cat commits.txt | while read line; do wget https://github.com/pinting/SuspiciousKeePassMini/archive/$line.zip; done
