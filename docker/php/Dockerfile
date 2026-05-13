ARG PHP_VERSION=8.4
FROM wordpress:php${PHP_VERSION}-apache

LABEL maintainer="WordPress Docker Dev Environment"

# ─── System tools + Xdebug (single layer = fewer cache layers) ──────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    less \
    msmtp \
    unzip \
    ${PHPIZE_DEPS} \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apt-get purge -y --auto-remove ${PHPIZE_DEPS} \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

# ─── Apache mod_rewrite (required by WordPress) ─────────────────────────────────
RUN a2enmod rewrite

# ─── WP-CLI (with SHA512 checksum verification) ─────────────────────────────────
RUN curl -sS -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && curl -sS -o /tmp/wp-cli.sha512 \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.sha512 \
    && echo "$(awk '{print $1}' /tmp/wp-cli.sha512)  /usr/local/bin/wp" | sha512sum -c - \
    && rm /tmp/wp-cli.sha512 \
    && chmod +x /usr/local/bin/wp

# ─── msmtp — mail routing to Mailpit ────────────────────────────────────────────
COPY msmtprc /etc/msmtprc
RUN chown root:www-data /etc/msmtprc && chmod 640 /etc/msmtprc

WORKDIR /var/www/html

# ─── Align www-data UID to host user UID ─────────────────────────────────────────
# Files created by Apache/PHP on the bind-mount volume
# will be owned by the host user — editable in VS Code without sudo.
ARG HOST_UID=1000
RUN existing=$(getent passwd "${HOST_UID}" | cut -d: -f1); \
    [ -n "$existing" ] && usermod -u 99999 "$existing"; \
    usermod -u "${HOST_UID}" www-data
