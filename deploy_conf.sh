#! /usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
  	exit 1
fi

APACHE_CONFIG="/etc/apache2/apache2.conf"
TMP_DIR=$(mktemp -d /tmp/data.XXXXXXXXXX) || { echo "Failed to create temp directory"; exit 1; }
SITE_ROOT="/var/www/html"

cd ${TMP_DIR}
git clone git://github.com/disconnect/apache-websocket.git
cd apache-websocket/examples
scons && sudo scons install && touch .installed

test ! -f .installed && { echo -e "\e[31mAn error occurred during the installation\e[0m"; exit 1; }

cp -v client.html  increment.html ${SITE_ROOT}

if ! grep -q "# BEGIN apache-websocket example" ${APACHE_CONFIG}; then
	cat >> /etc/apache2/apache2.conf <<_EOF

# BEGIN apache-websocket example
<IfModule mod_websocket.c>
  <Location /echo>
    SetHandler websocket-handler
    WebSocketHandler /usr/lib/apache2/modules/mod_websocket_echo.so echo_init
  </Location>
  <Location /dumb-increment>
    SetHandler websocket-handler
    WebSocketHandler /usr/lib/apache2/modules/mod_websocket_dumb_increment.so dumb_increment_init
  </Location>
</IfModule>

<IfModule mod_websocket_draft76.c>
  <Location /echo>
    SetHandler websocket-handler
    WebSocketHandler /usr/lib/apache2/modules/mod_websocket_echo.so echo_init
    SupportDraft75 On
  </Location>
  <Location /dumb-increment>
    SetHandler websocket-handler
    WebSocketHandler /usr/lib/apache2/modules/mod_websocket_dumb_increment.so dumb_increment_init
    SupportDraft75 On
  </Location>
</IfModule>
# END apache-websocket example

_EOF
fi

apache2ctl graceful

rm -r ${TMP_DIR}

echo -e "\e[32mCompleted\e[0m"
exit 0



















