#!/bin/bash
# Gera hash de senha no formato SHA-512 (compatível com /etc/shadow e kickstart)
if [ -z "$1" ]; then
  echo "Uso: $0 <senha>"
  exit 1
fi
openssl passwd -6 "$1"
