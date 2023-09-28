#!/bin/bash



sudo apt install apache2 mariadb-server mariadb-client unzip software-properties-common apt-transport-https ca-certificates
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install curl php7.4 php7.4-cli php7.4-common php7.4-curl php7.4-gd php7.4-intl php7.4-json php7.4-mbstring php7.4-mysql php7.4-opcache php7.4-readline php7.4-xml php7.4-xsl php7.4-zip php7.4-bz2 libapache2-mod-php7.4 
cd /usr/share 
sudo wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip -O phpmyadmin.zip 
sudo unzip phpmyadmin.zip 
sudo rm phpmyadmin.zip 
sudo mv phpMyAdmin-*-all-languages phpmyadmin 
sudo chmod -R 0755 phpmyadmin 

if ! cat /etc/apache2/conf-available/phpmyadmin.conf | grep -q "phpmyadmin signal"; then # AS IS
    echo "configuring phpmyadmin"
    tee /etc/apache2/conf-available/phpmyadmin.conf &> /dev/null 2>&1 << EOF
# phpMyAdmin Apache configuration

Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
</Directory>

# Disallow web access to directories that don't need it
<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
    Require all denied
</Directory>
#phpmyadmin signal
EOF
    a2enconf phpmyadmin
    mkdir /usr/share/phpmyadmin/tmp/
    chown -R www-data:www-data /usr/share/phpmyadmin/tmp/
    service mariadb start
    sleep 5
    mysql -u root --verbose < query.txt # mysql doeant like multiple commands so we have to run them from a file
    chmod -R o+wrx /opt/ # so we can add and remove files or edit them
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf &> /dev/null 2>&1  # This is needed to make php work inside html -i to save it without the need for > example.txt
    service apache2 reload
    # This part is for editing /etc/mysql/my.cnf file, so that it will accept connection from 3rd party database IDE
    echo -e "\n" >> /etc/mysql/my.cnf
    echo "[client]" >> /etc/mysql/my.cnf
    echo "port = 3306" >> /etc/mysql/my.cnf
    echo "socket = /tmp/mysql.sock" >> /etc/mysql/my.cnf
    echo -e "\n" >> /etc/mysql/my.cnf
    echo "[mysqld]" >> /etc/mysql/my.cnf
    echo "port = 3306" >> /etc/mysql/my.cnf
    echo "socket = /tmp/mysql.sock" >> /etc/mysql/my.cnf
    echo "skip-networking=0" >> /etc/mysql/my.cnf
    echo "skip-bind-addres" >> /etc/mysql/my.cnf
    # you need after that  to access inside the container with the command <docker exec -it leamp  bash> and type <mysql -uroot>  then type :
    service mariadb restart
    #done
    # mv /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php   #removing the sample and make it official 
    # service mariadb restart
else
    echo "No configuration needed for phpmyadmin"
fi