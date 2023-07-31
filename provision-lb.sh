#!/bin/bash
set -eux

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=haproxy.
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'

  _
 | |
 | |__   __ _ _ __  _ __ _____  ___   _
 | '_ \ / _` | '_ \| '__/ _ \ \/ / | | |
 | | | | (_| | |_) | | | (_) >  <| |_| |
 |_| |_|\__,_| .__/|_|  \___/_/\_\\__, |
             | |                   __/ |
             |_|                  |___/

EOF

# install and configure haproxy.
# see https://www.haproxy.com/blog/emulating-activepassing-application-clustering-with-haproxy/
apt-get install -y haproxy
haproxy -vv
# see https://ssl-config.mozilla.org/ffdhe2048.txt
install -m 444 /vagrant/ffdhe2048.txt /etc/haproxy/ffdhe2048.txt
cp /etc/haproxy/haproxy.cfg{,.ubuntu}
cat >/etc/haproxy/haproxy.cfg <<'EOF'
global
  log /dev/log    local0
  log /dev/log    local1 notice
  chroot /var/lib/haproxy
  stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
  stats timeout 30s
  user haproxy
  group haproxy
  daemon

  # Default SSL material locations
  ca-base /etc/ssl/certs
  crt-base /etc/ssl/private

  # Default ciphers to use on SSL-enabled listening sockets.
  # For more information, see ciphers(1SSL). This list is from:
  #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
  # An alternative list with additional directives can be obtained from
  #  https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
  # generated 2023-07-27, Mozilla Guideline v5.7, HAProxy 2.4, OpenSSL 3.0.2, intermediate configuration, no HSTS
  # https://ssl-config.mozilla.org/#server=haproxy&version=2.4&config=intermediate&openssl=3.0.2&hsts=false&guideline=5.7
  ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305
  ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
  ssl-default-bind-options prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
  ssl-default-server-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305
  ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
  ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
  ssl-dh-param-file /etc/haproxy/ffdhe2048.txt

defaults
  log     global
  mode    http
  option  httplog
  option  dontlognull
  timeout connect 5000
  timeout client  50000
  timeout server  50000
  errorfile 400 /etc/haproxy/errors/400.http
  errorfile 403 /etc/haproxy/errors/403.http
  errorfile 408 /etc/haproxy/errors/408.http
  errorfile 500 /etc/haproxy/errors/500.http
  errorfile 502 /etc/haproxy/errors/502.http
  errorfile 503 /etc/haproxy/errors/503.http
  errorfile 504 /etc/haproxy/errors/504.http

defaults
  mode tcp
  timeout client 20s
  timeout server 20s
  timeout connect 4s

listen stats
  bind 10.42.0.10:9000
  mode http
  stats enable
  stats uri /

listen app
  bind 10.42.0.11:80 name app
  stick-table type ip size 1 nopurge
  stick on dst
  option httpchk
  http-check connect port 3101
  http-check send meth GET uri /healthz ver HTTP/1.1 hdr Host app.example.com
  http-check expect status 200
  default-server check
  default-server inter 5s
  server web1 10.42.0.21:3100
  server web2 10.42.0.22:3100 backup

listen app_tls
  bind 10.42.0.11:443 name app
  stick-table type ip size 1 nopurge
  stick on dst
  option httpchk
  http-check connect port 4101 ssl sni app.example.com
  http-check send meth GET uri /healthz ver HTTP/1.1 hdr Host app.example.com
  http-check expect status 200
  default-server check ssl ca-file /usr/local/share/ca-certificates/example-ca.crt
  default-server inter 5s
  server web1 10.42.0.21:4100
  server web2 10.42.0.22:4100 backup
EOF
systemctl restart haproxy

echo 'show stat' | nc -U /run/haproxy/admin.sock
