#!/bin/bash

base_path=$(dirname $(readlink -f $0))

#php变量	
php_src="https://www.php.net/distributions/php-7.2.24.tar.gz"
php_tar=${php_src##*/}      #php-7.2.22.tar.gz
php_dir=${php_tar:0:10}     #php-7.2.22
php_path=/usr/local/php

#ngixn变量 
str="http://nginx.org/download/nginx-1.8.1.tar.gz"
ng_tar=${str##*/}       #nginx-1.8.1.tar.gz
ng_dir=${ng_tar:0:11}  #nginx-1.8.1
ng_path=/usr/local/nginx
config_file=nginx.conf

############################################################
function php_config(){

cp $base_path/$php_dir/php.ini-development $base_path/$php_dir/etc/php.ini  #cp php.ini-development /etc/php.ini
groupadd www-data  #groupadd www-data
useradd -M -g www-data -s /sbin/nologin www-data  #useradd -M -g www-data -s /sbin/nologin www-data
cp $php_path/etc/php-fpm.conf.default $php_path/etc/php-fpm.conf  #cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp $php_path/etc/php-fpm.d/www.conf.default $php_path/etc/php-fpm.d/www.conf #cd php-fpm.d #cp www.conf.default www.conf
sed -i '/^user=/c\user=www-data' $php_path/etc/php-fpm.d/www.conf
sed -i '/^group=/c\group=www-data' $php_path/etc/php-fpm.d/www.conf

}

############################################################
function ng_config(){

cd $ng_path/conf
cat>$config_file<<EOF

worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  localhost;
        
		location / {
            root   html;
            index  index.php index.html index.htm;
        }
       
	    location ~ \.php$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
            include        fastcgi_params;
        }

        
    }
}


EOF

touch $ng_path/html/index.php
echo '<?php phpinfo(); ?>' > $ng_path/html/index.php
}

############################################################
function check_env(){
soft=(wget vim gcc-c++ pcre-devel zlib-devel openssl openssl-devel epel-release libmcrypt-devel bzip2-devel gcc openssl-devel php-mcrypt libmcrypt libxml2-devel libjpeg-devel libpng-devel freetype-devel)
for i in ${soft[*]}
do
		yum install -y $i > /dev/null 2>&1
done

}
############################################################
function install_php(){
cd $base_path
wget $php_src
yum install -y epel-release libmcrypt-devel bzip2-devel gcc openssl-devel php-mcrypt libmcrypt libxml2-devel libjpeg-devel libpng-devel freetype-devel >/dev/null 2>&1
tar -xzvf $php_tar
cd $php_dir
./configure --prefix=$php_path --with-mysql=mysqlnd --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-openssl --enable-mbstring --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --enable-sockets --with-mcrypt  --with-bz2 --enable-fpm --with-gd --enable-bcmath
make -j4 && make -j4 install
php_config
}
############################################################
function install_mysql(){
yum install -y mariadb mariadb-server mariadb-devel > /dev/null 2>&1
echo "Mariadb depencies is installed"
systemctl start mariadb
#echo -e "\ny\n123456\n123456\n\n\n\n\n"|mysql_secure_installation
echo -e "\nY\n123456\n123456\nY\nn\nY\nY\n"|mysql_secure_installation
echo "Mariadb is installed"
}
############################################################
function install_ng(){
if [ ! -e $ng_path -a ! -e /etc/nginx ];then
yum install -y gcc-c++ pcre-devel zlib-devel openssl openssl-devel > /dev/null 2>&1
echo "ng__dependency is installed"
cd $base_path
wget $str
tar -xzvf $ng_tar
cd $ng_dir
./configure --prefix=$ng_path --with-http_ssl_module --with-http_sub_module --with-http_gzip_static_module --with-http_stub_status_module
make -j4 && make -j4 install
fi
ng_config
systemctl stop firewalld;sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/sysconfig/selinux
}

############################################################

echo "开始检查环境..."
sleep 5
echo "正在检查环境..."
check_env
echo "检查环境完毕..."

while :
do

cat <<EOF
################################################
#              1:安装 nginx                    #
#              2:安装 php                      #
#              3:安装 mysql                    #
#              4:退出                          #
################################################
EOF

read -p "请输入你要安装的:" n

case $n in
	4) break;;
	1) install_ng;;
	2)	install_php;;
	3) install_mysql;;
esac
done




