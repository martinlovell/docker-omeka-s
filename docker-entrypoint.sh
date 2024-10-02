#!/bin/sh

if [ ! -e config/database.ini ]; then
    cat > config/database.ini <<EOF
user = ${MYSQL_USER:-omeka-s}
password = ${MYSQL_PASSWORD:-omeka-s}
dbname = ${MYSQL_DATABASE:-omeka-s}
host = ${MYSQL_HOST:-mysql}
EOF
fi

/usr/local/libexec/bootstrap.sh

exec docker-php-entrypoint "$@"
