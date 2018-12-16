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
  ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
  ssl-default-bind-options no-sslv3

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

listen app1
  bind 10.42.0.11:80 name app1
  stick-table type ip size 1 nopurge
  stick on dst
  option httpchk GET /healthz HTTP/1.1\r\nHost:app1.example.com
  server web1 10.42.0.21:3100 check port 3101 inter 5s
  server web2 10.42.0.22:3100 check port 3101 inter 5s backup

listen app2
  bind 10.42.0.12:80 name app2
  stick-table type ip size 1 nopurge
  stick on dst
  option httpchk GET /healthz HTTP/1.1\r\nHost:app2.example.com
  server web1 10.42.0.21:3200 check port 3201 inter 5s
  server web2 10.42.0.22:3200 check port 3201 inter 5s backup
EOF
systemctl restart haproxy

echo 'show stat' | nc -U /run/haproxy/admin.sock
