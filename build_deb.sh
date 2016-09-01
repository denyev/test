#! /usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
  	exit 1
fi

function fix_permissions {
	chown -R $_LOGNAME:$_LOGNAME ${TMP_DIR}
	find ${TMP_DIR} -type d -exec chmod 0755 {} \;
	find ${TMP_DIR} -type f -exec chmod 0655 {} \;
}

_LOGNAME=$(logname)
TMP_DIR=$(mktemp -d /tmp/build_deb_package.XXXXXXXXXX) || { echo "Failed to create temp directory"; exit 1; }

cd ${TMP_DIR}

git clone https://github.com/disconnect/apache-websocket.git
mv -v apache-websocket apache-websocket-1.0
cd apache-websocket-1.0
rm -rf .git .gitignore

echo "env.Alias('run', os.system('strip mod_websocket.so mod_websocket_draft76.so'))" | tee -a SConstruct
#wget https://raw.githubusercontent.com/denyev/test/master/SConstruct -O SConstruct
sed -e "s#/usr/lib/apache2/modules#debian/libapache2-mod-websocket/usr/lib/apache2/modules#g" -i SConstruct

fix_permissions

sudo -u $_LOGNAME dh_make --yes --library --packagename apache-websocket_1.0.0 --email login@example.com --createorig

cd debian
rm -f *.ex *.EX *.dirs *.install *.docs *.source *.Debian

cat > control <<_EOF
Source: apache-websocket
Priority: optional
Maintainer: login@example.com
Build-Depends: debhelper (>=9)
Standards-Version: 3.9.6
Section: libs
Homepage: https://github.com/disconnect/apache-websocket

Package: libapache2-mod-websocket
Architecture: any
Depends: apache2-dev
Description: The apache-websocket module. 
 It is an Apache server module that may be used to process requests using the WebSocket protocol by an Apache server
_EOF


cat > rules <<"_EOF"
#!/usr/bin/make -f
# -*- makefile -*-
# Sample debian/rules that uses debhelper.
# This file was originally written by Joey Hess and Craig Small.
# As a special exception, when this file is copied by dh-make into a
# dh-make output file, you may use that output file without restriction.
# This special exception was added by Craig Small in version 0.37 of dh-make.

# Uncomment this to turn on verbose mode.
# export DH_VERBOSE=1


SCONS=scons

%:
	dh $@

override_dh_auto_build:
	$(SCONS) && $(SCONS) run

override_dh_auto_clean:
	dh_auto_clean
	$(SCONS) -c

override_dh_auto_install:
	$(SCONS) install
_EOF

cat > postinst <<"POSTINST_EOF"
#! /bin/sh

set -e
cat >> /etc/apache2/apache2.conf <<_EOF
# BEGIN apache-websocket
LoadModule websocket_module /usr/lib/apache2/modules/mod_websocket.so
LoadModule websocket_draft76_module /usr/lib/apache2/modules/mod_websocket_draft76.so
# END apache-websocket
_EOF

apache2ctl restart
exit 0

POSTINST_EOF

cat > postrm <<"POSTRM_EOF"
#! /bin/sh

set -e
sed -e "/# BEGIN apache-websocket/ ,/# END apache-websocket/d" -i /etc/apache2/apache2.conf
sed -e "/# BEGIN apache-websocket example/ ,/# END apache-websocket example/d" -i /etc/apache2/apache2.conf
cd /usr/lib/apache2/modules
for FILE in mod_websocket.so mod_websocket_draft76.so mod_websocket_echo.so mod_websocket_dumb_increment.so; do
    test -f ${FILE} && rm ${FILE}
done
apache2ctl restart
exit 0

POSTRM_EOF

sed -e "s#\* Initial release.*#\* New upstream release.#g" -i ${TMP_DIR}/apache-websocket-1.0/debian/changelog

# cat > changelog <<CHANGELOG_EOF
# apache-websocket (1.0.0-1) unstable; urgency=low
# 
#   * New upstream release.
# 
#  -- $_LOGNAME <login@example.com>  $(LANG=en_US; date "+%a, %d %b %Y %T %z") 
# CHANGELOG_EOF

cd ..

mkdir -pv debian/libapache2-mod-websocket/usr/lib/apache2/modules
mkdir -pv debian/libapache2-mod-websocket/etc/apache2/mods-available

touch debian/libapache2-mod-websocket/etc/apache2/mods-available/websocket.load
cat > debian/libapache2-mod-websocket/etc/apache2/mods-available/websocket.load <<_EOF
LoadModule websocket_module /usr/lib/apache2/modules/mod_websocket.so
_EOF

touch debian/libapache2-mod-websocket/etc/apache2/mods-available/websocket_draft76.load
cat > debian/libapache2-mod-websocket/etc/apache2/mods-available/websocket_draft76.load <<_EOF
LoadModule websocket_module /usr/lib/apache2/modules/mod_websocket_draft76.so
_EOF

dpkg-buildpackage -rfakeroot -us -uc

pwd
ls -Ahl --color=auto ${TMP_DIR}
sudo -u $_LOGNAME lintian ${TMP_DIR}/libapache2-mod-websocket_1.0.0-1_amd64.deb

exit 0
