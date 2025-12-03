#!/bin/bash
set -e

# Assure le dossier de volume côté host si variable fournie
[ -n "${HOST_WP}" ] && mkdir -p "${HOST_WP}"

# Attendre MariaDB
echo "⏳ Attente de MariaDB (${MYSQL_HOST:-mariadb}:3306)…"
until mysql -h"${MYSQL_HOST:-mariadb}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done
echo "✅ MariaDB OK"

# S'assurer que le volume bindé est accessible par l'utilisateur PHP-FPM (nobody)
chown -R nobody:nogroup /var/www/html
chmod -R u+rwX,g+rwX /var/www/html

# Augmenter la mémoire allouée au PHP CLI (WP-CLI) pour éviter les OOM sur download/extract
export WP_CLI_PHP_ARGS="-d memory_limit=512M"
export WP_CLI_CACHE_DIR="/tmp/wp-cli-cache"

# Installer WP-CLI si pas déjà
if ! command -v wp >/dev/null 2>&1; then
    curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x /usr/local/bin/wp
fi

cd /var/www/html

# Télécharger WordPress si index.php absent
if [ ! -f "wp-load.php" ]; then
    echo "⬇️  Téléchargement WordPress…"
    if ! wp core download --allow-root --version="${WP_VERSION:-latest}" --locale="${WP_LOCALE:-fr_FR}"; then
        echo "⚠️  wp-cli download a échoué, fallback via tar.gz"
        TMP_TGZ="/tmp/wordpress.tar.gz"
        curl -fsSL "https://wordpress.org/wordpress-${WP_VERSION:-latest}.tar.gz" -o "${TMP_TGZ}"
        tar -xzf "${TMP_TGZ}" -C /tmp
        cp -a /tmp/wordpress/. /var/www/html/
        rm -rf /tmp/wordpress "${TMP_TGZ}"
    fi
fi

# Config
if [ ! -f "wp-config.php" ]; then
    echo "⚙️  Génération wp-config.php…"
    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST:-mariadb}" \
        --locale="fr_FR" \
        --skip-check
fi

# Install site
if ! wp core is-installed --allow-root; then
    echo "🛠️  Installation WordPress…"
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"
    # User secondaire
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" --role=editor --user_pass="${WP_USER_PASSWORD}" --allow-root
fi

echo "🚀 Lancement PHP-FPM"
exec "$@"
