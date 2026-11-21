# Production container for TrackMauzo PHP API (replaces cPanel shared hosting)
FROM php:8.3-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
        libsqlite3-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite opcache \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache DocumentRoot to /var/www/html/public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Tune OPcache and PHP limits for high-concurrency POS syncs
RUN { \
      echo 'opcache.enable=1'; \
      echo 'opcache.memory_consumption=128'; \
      echo 'opcache.max_accelerated_files=4000'; \
      echo 'opcache.validate_timestamps=0'; \
      echo 'memory_limit=256M'; \
      echo 'max_execution_time=30'; \
    } > /usr/local/etc/php/conf.d/trackmauzo.ini

WORKDIR /var/www/html
COPY . /var/www/html

RUN mkdir -p /var/www/html/storage/uploads \
    && chown -R www-data:www-data /var/www/html/storage

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/api/health || exit 1
