FROM alpine:3.19

RUN apk add --no-cache nginx openssl bash

RUN mkdir -p /run/nginx /etc/nginx/ssl && \
    mkdir -p /var/www/html

# Conf Nginx
COPY conf/default.conf /etc/nginx/http.d/default.conf
# Entrypoint pour générer le certificat self-signed
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
