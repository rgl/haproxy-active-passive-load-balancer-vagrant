#!/bin/bash
set -eux

fqdn="app.$(hostname --domain)"

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
install -g app -m 440 "/vagrant/shared/example-ca/$fqdn-crt.pem" /opt/app
install -g app -m 440 "/vagrant/shared/example-ca/$fqdn-key.pem" /opt/app
install -g app -m 440 "/vagrant/shared/example-ca/example-ca-crt.pem" /opt/app

# launch the app.
cat >/etc/systemd/system/app.service <<EOF
[Unit]
Description=Example Web Application
After=network.target

[Service]
Type=simple
User=app
Group=app
Environment=NODE_ENV=production
ExecStart=/usr/bin/node main.js $fqdn 3100 3101 4100 4101
WorkingDirectory=/opt/app
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
systemctl enable app
systemctl start app
sleep .2

# try http.
curl \
    --verbose \
    --no-progress-meter \
    --fail \
    --output - \
    --resolve $fqdn:3100:127.0.0.1 \
    http://$fqdn:3100/try

# try https using the system cas.
curl \
    --verbose \
    --no-progress-meter \
    --fail \
    --output - \
    --cert /vagrant/shared/example-ca/$fqdn-client-crt.pem \
    --key /vagrant/shared/example-ca/$fqdn-client-key.pem \
    --resolve $fqdn:4100:127.0.0.1 \
    https://$fqdn:4100/try

# try https using just the expected ca.
export CURL_CA_BUNDLE=/usr/local/share/ca-certificates/example-ca.crt
curl \
    --verbose \
    --no-progress-meter \
    --fail \
    --output - \
    --cert /vagrant/shared/example-ca/$fqdn-client-crt.pem \
    --key /vagrant/shared/example-ca/$fqdn-client-key.pem \
    --resolve $fqdn:4100:127.0.0.1 \
    https://$fqdn:4100/try
unset CURL_CA_BUNDLE

# see the tls certificate validation result.
# NB should have verify return:1.
(printf "GET /try HTTP/1.1\r\nHost: $fqdn\r\n\r\n" && sleep .2) | openssl \
    s_client \
    -connect 127.0.0.1:4100 \
    -servername $fqdn \
    -CAfile /usr/local/share/ca-certificates/example-ca.crt \
    -cert /vagrant/shared/example-ca/$fqdn-client-crt.pem \
    -key /vagrant/shared/example-ca/$fqdn-client-key.pem
