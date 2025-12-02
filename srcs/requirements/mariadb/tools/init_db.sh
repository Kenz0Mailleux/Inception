#!/bin/bash
set -e

# 0) Permissions sûres à chaque boot
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "🔧 Initialisation MariaDB…"
  mariadb-install-db --user=mysql --ldata=/var/lib/mysql > /dev/null

  # 1) Bootstrap: root en mot de passe "classique", DB + users (+ variantes host)
  mysqld --user=mysql --bootstrap <<-EOSQL
    FLUSH PRIVILEGES;
    ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_ROOT_PASSWORD}');
    DELETE FROM mysql.user WHERE User='' OR (User='root' AND Host NOT IN ('localhost'));
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db IN ('test','test\\_%');

    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`
      CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';

    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'127.0.0.1';

    FLUSH PRIVILEGES;
EOSQL
else
  # Déjà initialisé : on ne retouche pas les grants pour éviter l'erreur skip-grant-tables
  echo "✅ MariaDB déjà initialisé — démarrage direct"
fi

echo "🚀 Lancement mysqld (TCP 3306)"
# Force l'écoute TCP (sinon port=0) et garde le socket local pour le healthcheck
exec mysqld --user=mysql \
  --bind-address=0.0.0.0 \
  --port=3306 \
  --skip-networking=0 \
  --skip-name-resolve \
  --socket=/run/mysqld/mysqld.sock \
  --console
