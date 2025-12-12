#!/usr/bin/env bash
set -e
# Usage: bootstrap_marlon.sh CONTROL_URL TOKEN TENANT_SLUG
CONTROL_URL=${1:-"https://control.lightek.com/marlon/gatekeeper"}
TOKEN=${2:-"change_me"}
TENANT=${3:-"unknown"}

# install base packages (debian/ubuntu example)
apt-get update
apt-get install -y build-essential git curl wget gnupg2 libssl-dev libpq-dev

# install rbenv/ruby or use system ruby; for simplicity use system ruby (install via apt)
apt-get install -y ruby ruby-dev bundler

# create app dir
mkdir -p /srv/marlon
cd /srv/marlon

# initial marlon install - using gem approach (if marlon gem published or use tar bundle)
# For initial bootstrap we fetch a lightweight marlon runtime or bundle from control-plane
# Example: fetch bootstrap script from control-plane and run it (control-plane should host rpm/tgz)
curl -sS "${CONTROL_URL%/}/bootstrap/#{TENANT}" -H "X-MARLON-TOKEN: ${TOKEN}" | bash

# install agent systemd unit
cat >/etc/systemd/system/marlon-agent.service <<'UNIT'
[Unit]
Description=Marlon Agent
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/env ruby /srv/marlon/agent_runner.rb
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

# enable and start agent
systemctl daemon-reload
systemctl enable --now marlon-agent

echo "BOOTSTRAP COMPLETE"
