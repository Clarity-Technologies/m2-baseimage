# Base image is PHP 7.3 running Apache

# FIX We want to build magento with PHP 7.3
FROM php:7.3-apache

LABEL company="Clarity"
# LABEL maintainer="manash@raytax"

# Install Magento 2 dependencies
# FIX We have to change two package names
#     - libpng12-dev -> libpng-dev
#     - mysql-client -> default-mysql-client
RUN apt-get update && apt-get install -y \
        cron \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        # libxml2-dev \
        libxslt1-dev \
        libicu-dev \
        # FIX COMMENTED # mysql-client \
        default-mysql-client \
        libzip-dev \
        # xmlstarlet \
    && docker-php-ext-install -j$(nproc) bcmath \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pcntl \
    && docker-php-ext-install -j$(nproc) soap \
    && docker-php-ext-install -j$(nproc) xsl \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) intl \
    # && docker-php-ext-install -j$(nproc) pdo \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && pecl install redis-5.0.2 \
    && docker-php-ext-enable redis \
    && a2enmod rewrite headers \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && php -m

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Set up the application
COPY src /var/www/html/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY etc/php.ini /usr/local/etc/php/conf.d/00_magento.ini
COPY etc/apache.conf /etc/apache2/conf-enabled/00_magento.conf

# Copy hooks
COPY hooks /hooks/

# Set default parameters
ENV MYSQL_HOSTNAME="mysql" MYSQL_USERNAME="root" MYSQL_PASSWORD="secure" MYSQL_DATABASE="magento" CRYPT_KEY="" \
    URI="http://localhost" ADMIN_USERNAME="admin" ADMIN_PASSWORD="adm1nistrator" ADMIN_FIRSTNAME="admin" \
    ADMIN_LASTNAME="admin" ADMIN_EMAIL="admin@example.com" CURRENCY="INR" LANGUAGE="en_US" \
    TIMEZONE="Asia/Kolkata" BACKEND_FRONTNAME="admin" CONTENT_LANGUAGES="en_US"

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]