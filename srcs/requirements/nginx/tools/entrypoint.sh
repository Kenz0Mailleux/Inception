#!/bin/bash
set -e

DOMAIN="${DOMAIN_NAME:-kmailleu.42.fr}"
SSL_DIR="/etc/nginx/ssl"

# Générer un certificat auto-signé si absent (valable 365j)
if [ ! -f "${SSL_DIR}/server.crt" ] || [ ! -f "${SSL_DIR}/server.key" ]; then
  echo "🔐 Génération certificat pour ${DOMAIN}"
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "${SSL_DIR}/server.key" \
    -out "${SSL_DIR}/server.crt" \
    -days 365 \
    -subj "/C=BE/ST=Brussels/L=Brussels/O=42/OU=Student/CN=${DOMAIN}"
fi

exec "$@"
