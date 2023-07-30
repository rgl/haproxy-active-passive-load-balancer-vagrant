#!/bin/bash
set -eux

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=backend%0Aweb%20server
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'
               _
              | |
 __      _____| |__
 \ \ /\ / / _ \ '_ \
  \ V  V /  __/ |_) |
   \_/\_/ \___|_.__/

EOF

# add the app user.
groupadd --system app
adduser \
    --system \
    --disabled-login \
    --no-create-home \
    --gecos '' \
    --ingroup app \
    --home /opt/app \
    app
install -d -o root -g app -m 750 /opt/app

# install the example application and run it as a systemd service.
install /vagrant/app/* /opt/app

# launch two apps: app1 (port 3100 and 3101) and app2 (port 3200 and 3201).
for n in 1 2; do
    port="3${n}00"
    healthz_port="3${n}01"
    cat >/etc/systemd/system/app$n.service <<EOF
[Unit]
Description=Example Web Application
After=network.target

[Service]
Type=simple
User=app
Group=app
Environment=NODE_ENV=production
ExecStart=/usr/bin/node main.js $port $healthz_port
WorkingDirectory=/opt/app
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable app$n
    systemctl start app$n
done

# try it.
sleep .2
wget -qO- localhost:3100/try
wget -qO- localhost:3200/try
