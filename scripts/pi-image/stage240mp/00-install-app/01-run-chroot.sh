#!/bin/bash -e

source /tmp/240mp-image.env
source /tmp/240mp-pi-setup.sh

cd /opt/240mp-src
cmake -B build -DCMAKE_BUILD_TYPE=Release .
cmake --build build --parallel "$(nproc)"
cmake --install build --prefix /opt/240mp

pi240_create_service_user "$PI240_SERVICE_USER" "$PI240_SERVICE_HOME"
pi240_install_tty_rule
pi240_install_launcher /opt/240mp /usr/local/bin/240mp
pi240_install_autostart "$PI240_SERVICE_USER" /usr/local/bin/240mp /etc/systemd/system/240mp.service "$PI240_SERVICE_HOME"
pi240_install_update_helper "$PI240_SERVICE_USER" /usr/local/sbin/240mp-update /opt/240mp/share/240mp/scripts/240mp-update

# apt-listchanges can spend a long time fetching remote changelogs during
# pi-gen's export finalise step, and transient DNS failures can stall the build.
rm -f /etc/apt/apt.conf.d/20listchanges

rm -rf /opt/240mp-src /tmp/240mp-image.env /tmp/240mp-pi-setup.sh
apt-get clean
rm -rf /var/lib/apt/lists/*
