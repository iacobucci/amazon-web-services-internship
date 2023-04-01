#!/bin/bash

$REPO=/var/www/efs/express-aws

function install_packages {
	yum update -y
	amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
	amazon-linux-extras install -y nginx1
	yum install -y amazon-efs-utils
	yum install -y rsync
	yum install -y git

	curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
	yum install -y nodejs
}

function mount_efs {
	mkdir -p /var/www/efs
	echo "
10.55.15.43:/           /var/www/efs    nfs4            rw,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,hard,noresvport,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.55.5.226,local_lock=none,addr=10.55.15.43        0 0     
" >>/etc/fstab
	mount -a
}

function install_repo {
	rm -rf /var/www/efs/express-aws
	git clone https://github.com/iacobucci/express-aws $REPO

	for f in $REPO/res; do
		rsync -avr $f /
	done

	chown -R nginx:nginx /var/www/efs/express-aws
}

function write_config {
	mkdir -p /var/www/helloworld
	echo ciao >/var/www/helloworld/index.html
	chown -R apache:apache /var/www/helloworld

	awk '/^listen = / {$3="/run/php-fpm/www.sock;"} 1' /etc/php-fpm.d/www.conf >/etc/php-fpm.d/www.conf.new
	mv /etc/php-fpm.d/www.conf.new /etc/php-fpm.d/www.conf
}

function install_filemanager {
	echo installing lf
	lflink=https://github.com/gokcehan/lf/releases/download/r28/lf-linux-amd64.tar.gz
	wget $lflink --output-document=lf.tar
	tar -xvf lf.tar
	rm lf.tar
	mv lf /bin

	cat $GIT_DIR/res/etc/profile.d/lf.sh >/etc/profile.d/lf.sh
}

function install_aws_cli {
	# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	# unzip awscliv2.zip
	# ./aws/install
	# rm -rf aws awscliv2.zip
	echo -e "\n\neu-north-1\njson\n" | aws configure
}

function install_node_server {
	cd $REPO
	npm install
	npm run build
}

function enable_servers {
	systemctl enable --now php-fpm
	systemctl enable --now express-aws
	systemctl enable --now nginx
}

install_packages
mount_efs
install_repo
write_config
install_filemanager
install_aws_cli
install_node_server
enable_servers
