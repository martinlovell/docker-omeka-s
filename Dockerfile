FROM php:8.0-apache

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
    && echo "deb https://deb.nodesource.com/node_10.x buster main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y npm \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g gulp-cli \
    && adduser --disabled-password --gecos '' omeka-s

RUN git clone --depth 1 --branch v3.2.3 https://github.com/omeka/omeka-s.git . \
    && npm install \
    && gulp init \
    && rm -f config/database.ini \
    && chown -R omeka-s:omeka-s .

RUN wget https://github.com/omeka-s-modules/Mapping/releases/download/v1.6.0/Mapping-1.6.0.zip \
    && unzip Mapping-1.6.0.zip -d /var/www/html/modules \
    && rm Mapping-1.6.0.zip

RUN wget https://github.com/omeka-s-modules/FacetedBrowse/releases/download/v1.2.0/FacetedBrowse-1.2.0.zip \
    && unzip FacetedBrowse-1.2.0.zip -d /var/www/html/modules \
    && rm FacetedBrowse-1.2.0.zip


RUN wget https://github.com/omeka-s-modules/MetadataBrowse/releases/download/v1.5.1/MetadataBrowse-1.5.1.zip \
    && unzip MetadataBrowse-1.5.1.zip -d /var/www/html/modules \
    && rm MetadataBrowse-1.5.1.zip


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
