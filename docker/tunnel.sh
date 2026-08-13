#!/bin/sh
set -e
apk add --no-cache openssh-client netcat-openbsd curl
cp /root/.ssh/jetstream2 /tmp/jetstream2
chmod 600 /tmp/jetstream2
exec ssh -N \
  -o StrictHostKeyChecking=no \
  -o IdentitiesOnly=yes \
  -o IdentityAgent=none \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes \
  -i /tmp/jetstream2 \
  -L 0.0.0.0:11435:149.165.156.93:443 \
  exouser@${PONS1_IP}
Rscript -e "install.packages(c('ellmer'), contrib_url = 'https://cran.r-project.org')"
