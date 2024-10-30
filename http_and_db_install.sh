#!/bin/bash

# Make sure root user
if [[ $EUID -ne 0 ]]; then
   echo "Run with sudo!!!!"
   exit 1
fi

# Install packages
echo "Installing needed packages"
# enable EPEL repo for needed version of php
yum install epel-release -y
yum install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y
yum module reset php -y
yum module enable php:remi-8.1 -y

yum install -y httpd mariadb-server php-8.1.0 php-mysqlnd php-xml php-mbstring php-intl php-json php-gd tar wget

# Start Apache and MariaDB
echo "Starting services"
systemctl start httpd
systemctl enable httpd
systemctl start mariadb
systemctl enable mariadb

# allow http through firewall
firewall-cmd --permanent --add-service=http
firewall-cmd --reload


# Database variables
read -p "Database Username: " DB_USER
read -s -p -e "Database Password\n" DB_PASS # user -s tac on read to not show password
DB_NAME="mediawiki"

# Create the database needed for mediawiki and user
echo "Creating Database"
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME; # create the database
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; # create the user for the db and assign it the password
GRANT ALL PRIVILEGS ON $DB_NAME.*TO '$DB_USER'@'localhost'; # allow the user to read/write/modify on db
FLUSH PRIVILEGES; # apply the privilegs
MYSQL_SCRIPT
# end of sql script
echo "Database Has Been Created"

# Download media wiki
echo "Downlaoding Media Wiki"
wget https://releases.wikimedia.org/mediawiki/1.42/mediawiki-1.42.3.tar.gz -P /tmp # get the media wiki and save in  tmp file
tar -zxvf /tmp/mediawiki-1.42.3.tar.gz -C /var/www/html # unzip and copy contents to apache webserver root
mv /var/www/html/mediawiki-1.42.3 "/var/www/html/mediawiki"

# Ensure correct permission are set
chown -R apache:apache "/var/www/html/mediawiki"
chmod -R 755 "/var/www/html/mediawiki"

# configure apache to use mediawiki
echo "Configuring Apache For Media Wiki"
cat <<EOL > /etc/httpd/conf.d/mediawiki.conf
<VirtualHost *:80>
   DocumentRoot "/var/www/html/mediawiki"
    <Directory "/var/www/html/mediawiki">
         Options FollowSymLinks
         AllowOverride All
         Require all granted
      </Directory>
</VirtualHost>
EOL

echo -e "Apache Configured \n Restarting apache now\nn"
systemctl restart httpd

echo "Media wiki should now be installed"
server_name=$(hostname)
echo "View http://$hostname/mediawiki"

