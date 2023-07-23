#!/bin/bash

apt update >/dev/null 2>&1

parted -s /dev/sdc mklabel gpt
parted -s -a optimal /dev/sdc mkpart logical 0% 100%
parted -s /dev/sdc 'set 1 lvm on'
pvcreate /dev/sdc1
vgcreate vg_data /dev/sdc1
lvcreate -l 100%FREE -n lv_mysql vg_data
mkfs.ext4 /dev/vg_data/lv_mysql
mkdir -p /var/lib/mysql
echo "/dev/vg_data/lv_mysql /var/lib/mysql ext4 defaults 0 0" | tee -a /etc/fstab
mount -a

apt-get install -y nginx mariadb-server mariadb-common php-fpm php-mysql expect php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip >/dev/null 2>&1

#Crear site Nginx para wordpress
cat > /etc/nginx/sites-available/wordpress << END
# Managed by installation script - Do not change
server {
			listen 80;
			root /var/www/wordpress;
			index index.php index.html index.htm index.nginx-debian.html;
			server_name localhost;
			location / {
                try_files \$uri \$uri/ =404;
                }
			location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
			fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
										}
			location ~ /\.ht {
			deny all;
			}
		}
END


#Creacion usuarios BD Wordpress
mysql -uroot -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;" 
mysql -uroot -e "GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'keepcoding';"
mysql -uroot -e "FLUSH privileges;"


#Securizar MySQL
mysql_secure_installation << EOF

y
keepcoding
keepcoding
y
y
y
y
EOF

mysql -uroot -e "update mysql.user set plugin='' where User='root';"
mysql -uroot -e "FLUSH privileges;"

#wp-config
#sed '23,29 d' </var/www/wordpress/wp-config-sample.php >/var/www/wordpress/wp-config.php && sed '23 a define( "DB_NAME", "wordpress" );' -i /var/www/wordpress/wp-config.php && sed '24 a / Database username */' -i /var/www/wordpress/wp-config.php && sed '25 a define( "DB_USER", "wordpressuser" );' -i /var/www/wordpress/wp-config.php && sed '26 a / Database password */' -i /var/www/wordpress/wp-config.php && sed '27 a define( "DB_PASSWORD", "keepcoding" );' -i /var/www/wordpress/wp-config.php


#Desplieegue Wordpress
wget https://wordpress.org/latest.tar.gz >/dev/null 2>&1
tar -xf latest.tar.gz -C /var/www/ 
chown -R www-data:www-data /var/www/wordpress/
chmod -R 755 /var/www/wordpress/

#wp-config
sed '23,29 d' </var/www/wordpress/wp-config-sample.php >/var/www/wordpress/wp-config.php && sed '23 a define( "DB_NAME", "wordpress" );' -i /var/www/wordpress/wp-config.php && sed '24 a / Database username */' -i /var/www/wordpress/wp-config.php && sed '25 a define( "DB_USER", "wordpressuser" );' -i /var/www/wordpress/wp-config.php && sed '26 a / Database password */' -i /var/www/wordpress/wp-config.php && sed '27 a define( "DB_PASSWORD", "keepcoding" );' -i /var/www/wordpress/wp-config.php

#Configurar Nginx para Wordpress
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress
rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default
systemctl restart nginx





#Instalacion Filebeat
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list
apt-get update && apt-get install filebeat

filebeat modules enable system
filebeat modules enable nginx

cat > /etc/filebeat/filebeat.yml << END
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/nginx/*.log
    - /var/log/mysql/*.log	
filebeat.config.modules:
  path: /etc/filebeat/modules.d/*.yml
  reload.enabled: true
setup.template.settings:
  index.number_of_shards: 3
output.logstash:
  hosts: ["192.168.56.11:5044"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
END

systemctl enable filebeat.service --now



exit 0
