FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
        git \
        gnupg \
        imagemagick \
        libcurl4-gnutls-dev \
        libxml2-dev \
        libicu-dev \
        unzip \
        vim \
        apache2 \
        wget \
    && docker-php-ext-install intl pdo_mysql \
    && pecl install solr-2.5.1 \
    && docker-php-ext-enable solr \
    && cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini \
    && a2enmod rewrite \
    && curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo "deb https://deb.nodesource.com/node_14.x buster main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs npm \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g gulp-cli \
    && adduser --disabled-password --gecos '' omeka-s

RUN git clone --depth 1 --branch v4.1.1 https://github.com/omeka/omeka-s.git . \
    && npm install \
    && gulp init \
    && rm -f config/database.ini \
    && chown -R omeka-s:omeka-s .

RUN wget https://github.com/omeka-s-modules/Mapping/releases/download/v2.0.0/Mapping-2.0.0.zip \
    && unzip Mapping-2.0.0.zip -d /var/www/html/modules \
    && rm Mapping-2.0.0.zip

RUN wget https://github.com/Daniel-KM/Omeka-S-module-Common/releases/download/3.4.62/Common-3.4.62.zip \
    && unzip Common-3.4.62.zip -d /var/www/html/modules \
    && rm Common-3.4.62.zip

RUN wget https://github.com/Daniel-KM/Omeka-S-module-AdvancedSearch/releases/download/3.4.31/AdvancedSearch-3.4.31.zip \
    && unzip AdvancedSearch-3.4.31.zip -d /var/www/html/modules \
    && rm AdvancedSearch-3.4.31.zip



RUN echo 'SetEnv APPLICATION_ENV "development"' >> /var/www/html/.htaccess

COPY bootstrap.sh /usr/local/libexec/
COPY bootstrap.d/*.php /usr/local/libexec/bootstrap.d/
COPY docker-entrypoint.sh /usr/local/bin/
COPY schemaorg.rdf schemaorg.rdf
COPY dbpedia.nt dbpedia.nt
COPY schemaorg_full.rdf schemaorg_full.rdf
COPY dbpedia_full.nt dbpedia_full.nt

VOLUME ["/var/www/html/files", "/var/www/html/logs", "/var/www/html/config"]

ENV LANG C.UTF-8
ENV APACHE_RUN_USER omeka-s
ENV APACHE_RUN_GROUP omeka-s

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
