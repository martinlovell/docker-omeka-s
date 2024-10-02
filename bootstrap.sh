#!/bin/sh

DIR=$(dirname "$(readlink -f "$0")")

/bin/ls "$DIR/bootstrap.d/"*.php | while read script; do
    /usr/local/bin/php $script
done
