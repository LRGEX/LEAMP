#!/bin/bash
# source /opt/backarosa/backup
cat << "EOF"
██╗     ██████╗  ██████╗ ███████╗██╗  ██╗
██║     ██╔══██╗██╔════╝ ██╔════╝╚██╗██╔╝
██║     ██████╔╝██║  ███╗█████╗   ╚███╔╝ 
██║     ██╔══██╗██║   ██║██╔══╝   ██╔██╗ 
███████╗██║  ██║╚██████╔╝███████╗██╔╝ ██╗
╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ 
╦  ┌─┐┌─┐┌┬┐┌─┐
║  ├┤ ├─┤│││├─┘
╩═╝└─┘┴ ┴┴ ┴┴    v1.0                                  
EOF
ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone # Set timezone for ubuntu
env >> /etc/environment # This is needed for variables to be available to cron jobs or other programs

if ! cat /opt/leamp/LRGEX.signals | grep -q "phpmyadmin signal"; then # AS IS
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
EOF
    a2enconf phpmyadmin
    mkdir /usr/share/phpmyadmin/tmp/
    touch /var/www/.htaccess
    echo "AddHandler application/x-httpd-php .html" > /var/www/.htaccess
    chown -R www-data:www-data /usr/share/phpmyadmin/tmp/
    chmod -R o+wrx /opt/leamp # so we can add and remove files or edit them
    echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf &> /dev/null 2>&1  # This is needed to make php work inside html -i to save it without the need for > example.txt
    # adduser --system --uid=$(stat -c %u .) "$owner"
    # echo "APACHE_RUN_USER=$owner" >> /etc/apache2/envvars
    service apache2 reload
    sleep 5
    # This part is for editing /etc/mysql/my.cnf file, so that it will accept connection from 3rd party database IDE
    rm -r /etc/mysql/my.cnf
    touch /etc/mysql/my.cnf
    tee /etc/mysql/my.cnf &> /dev/null 2>&1 << EOF
[client-server]
# Port or socket location where to connect
port = 3306
socket = /run/mysqld/mysqld.sock

# Import all .cnf files from configuration directory

!includedir /etc/mysql/mariadb.conf.d/
!includedir /etc/mysql/conf.d/


[client]
port = 3306
socket = /run/mysqld/mysqld.sock


[mysqld]
port = 3306
socket = /run/mysqld/mysqld.sock
skip-networking=0
skip-bind-address
EOF
    # you need after that  to access inside the container with the command <docker exec -it leamp  bash> and type <mysql -uroot>  then type : 
    service mariadb start
    sleep 5
    mysql -u root < /opt/leamp/scripts/query.txt # mysql doeant like multiple commands so we have to run them from a file
    echo "phpmyadmin signal" >> /opt/leamp/LRGEX.signals 
else
    echo "No configuration needed for phpmyadmin"
    service mariadb start
fi

# this condition for installing optional packages

# set a trap to catch SIGTERM and SIGINT signals so we can exit gracefully
#exit the container when the script is finished
trap 'exit' SIGTERM SIGINT
# if $signal == "done" ; then
#     kill -s SIGTERM 1
# fi
exec "$@" & wait # This is needed to run other scripts or commands when running the container like docker run -it --rm backarosa:latest /bin/bash, backup,restore,container_start,container_stop ..etc
#so when you run the container it will run only one command from scripts folder and exit, however commands in line 3 and 4 will run on every docker run - mandatory hard coded - 