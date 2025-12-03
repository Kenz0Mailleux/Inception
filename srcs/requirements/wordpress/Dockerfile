FROM alpine:3.19

RUN apk add --no-cache \
    php82 php82-fpm php82-mysqli php82-json php82-opcache php82-curl \
    php82-dom php82-exif php82-fileinfo php82-mbstring php82-xml php82-zip \
    php82-phar php82-tokenizer php82-session php82-ctype php82-pecl-imagick \
    curl bash mariadb-client

# Dossier WP
RUN mkdir -p /home/kmailleu/data/wordpress
RUN mkdir -p /var/www/html && chown -R nobody:nogroup /var/www/html

# PHP-FPM config minimale
RUN sed -i 's|^;cgi.fix_pathinfo=.*|cgi.fix_pathinfo=0|g' /etc/php82/php.ini && \
    sed -i 's|^user = .*|user = nobody|g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's|^group = .*|group = nogroup|g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's|^listen = .*|listen = 0.0.0.0:9000|g' /etc/php82/php-fpm.d/www.conf

COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]
CMD ["php-fpm82", "-F"]
