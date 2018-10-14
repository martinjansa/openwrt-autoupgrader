local-deploy:
	mkdir -p /usr/local/sbin
	cp ./bin/openwrt-autoupgrader-remote-upgrade.sh /usr/local/sbin

remote-deploy:	
	./bin/openwrt-autoupgrader-deploy.sh
