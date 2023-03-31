#!/bin/bash

function install_packages {
yum update -y
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
amazon-linux-extras install -y nginx1
yum install -y amazon-efs-utils

# node server
yum install -y git
curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
yum install -y nodejs
}

function write_config {
mkdir -p /var/www
mkdir -p /var/www/helloworld
echo ciao > /var/www/helloworld/index.html
chown -R apache:apache /var/www/helloworld

echo 'server {
listen 80;

server_name valerio.sandbox.soluzionifutura.it;
root /var/www/efs/wordpress;
include /etc/nginx/default.d/*.conf;
}
' > /etc/nginx/conf.d/wordpress.conf

echo 'server {
listen 80; 

server_name _;

root /var/www/helloworld;
index index.html;

location / { 
try_files $uri $uri/ =404;
}   
}
' > /etc/nginx/conf.d/helloworld.conf

echo '# pass the PHP scripts to FastCGI server
#
# See conf.d/php-fpm.conf for socket configuration
#
index index.php index.html index.htm;

location ~ \.(php|phar)(/.*)?$ {
    fastcgi_split_path_info ^(.+\.(?:php|phar))(/.*)$;

    fastcgi_intercept_errors on;
    fastcgi_index  index.php;
    include        fastcgi_params;
    fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
    fastcgi_param  PATH_INFO $fastcgi_path_info;
    fastcgi_param  HTTPS $fastcgi_https;
    fastcgi_pass   php-fpm;
}
' > /etc/nginx/default.d/php.conf

echo 'map $http_x_forwarded_proto $fastcgi_https {
        default         off;
        http            off;
        https           on;
}
' > /etc/nginx/conf.d/x_forwarded_proto_https.conf

echo '# PHP-FPM FastCGI server
# network or unix domain socket configuration

upstream php-fpm {
        server unix:/run/php-fpm/www.sock;
}
' > /etc/nginx/conf.d/php-fpm.conf

awk '/^listen = / {$3="/run/php-fpm/www.sock;"} 1' /etc/php-fpm.d/www.conf > /etc/php-fpm.d/www.conf.new
mv /etc/php-fpm.d/www.conf.new /etc/php-fpm.d/www.conf
}

function mount_efs {

mkdir -p /var/www/efs

echo "
10.55.15.43:/           /var/www/efs    nfs4            rw,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,hard,noresvport,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.55.5.226,local_lock=none,addr=10.55.15.43        0 0     
" >> /etc/fstab

mount -a

}

function enable_servers {
systemctl enable --now php-fpm
systemctl enable --now nginx
}

function install_filemanager {
echo installing lf
lflink=https://github.com/gokcehan/lf/releases/download/r28/lf-linux-amd64.tar.gz
wget $lflink --output-document=lf.tar
tar -xvf lf.tar 
rm lf.tar
mv lf /bin

echo 'lfcd () {
tmp="$(mktemp)"
# `command` is needed in case `lfcd` is aliased to `lf`
command lf -last-dir-path="$tmp" "$@"
if [ -f "$tmp" ]; then
dir="$(cat "$tmp")"
rm -f "$tmp"
if [ -d "$dir" ]; then
if [ "$dir" != "$(pwd)" ]; then
cd "$dir"
fi
fi
fi
}

alias lf="lfcd "
' > /etc/profile.d/lf.sh


}

function install_aws_cli {
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# ./aws/install
# rm -rf aws awscliv2.zip

echo -e "\n\neu-north-1\njson\n" | aws configure
}


function install_node_server {
rm -rf /var/www/efs/express-aws ; git clone https://github.com/iacobucci/express-aws /var/www/efs/express-aws
cd /var/www/efs/express-aws
npm install

#nginx configuration

}

install_packages
write_config
mount_efs
install_filemanager
install_aws_cli
install_node_server
enable_servers
