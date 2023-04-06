#!/bin/bash

function install_packages {
	yum update -y
	yum install -y amazon-efs-utils rsync git ruby wget

	amazon-linux-extras install -y nginx1
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

function write_config {
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

	echo '
	#!/bin/bash
	lfcd() {
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

function install_codedeploy {
	wget https://aws-codedeploy-eu-north-1.s3.eu-north-1.amazonaws.com/latest/install
	ruby ./install auto
	service codedeploy-agent start
}

function start_nginx {
	systemctl start nginx
}

install_packages
mount_efs
write_config
install_filemanager
install_aws_cli
start_nginx
install_codedeploy