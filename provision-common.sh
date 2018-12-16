#!/bin/bash
set -eux

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# update the package cache.
apt-get update

# install vim.
apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF

# configure the shell.
cat >/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

# install tcpdump to locally being able to capture network traffic.
apt-get install -y tcpdump

# install dumpcap to remotely being able to capture network traffic using wireshark.
groupadd --system wireshark
usermod -a -G wireshark vagrant
cat >/usr/local/bin/dumpcap <<'EOF'
#!/bin/sh
# NB -P is to force pcap format (default is pcapng).
# NB if you don't do that, wireshark will fail with:
#       Capturing from a pipe doesn't support pcapng format.
exec /usr/bin/dumpcap -P "$@"
EOF
chmod +x /usr/local/bin/dumpcap
echo 'wireshark-common wireshark-common/install-setuid boolean true' | debconf-set-selections
apt-get install -y --no-install-recommends wireshark-common

# install node LTS for our example applications.
# see https://github.com/nodesource/distributions#debinstall
apt-get install -y curl gnupg
curl -sL https://deb.nodesource.com/setup_10.x | bash
apt-get install -y nodejs
node --version
npm --version
