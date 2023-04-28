#!/usr/bin/env bash

cd $DEPLOY_PATH/website

mkdir -p storage/app/public
mkdir -p storage/framework/cache/data
mkdir -p storage/framework/sessions
mkdir -p storage/framework/testing
mkdir -p storage/framework/views

rm -rf bootstrap/cache/*.php
php81 artisan package:discover --ansi

php81 artisan cache:clear
php81 artisan config:clear
php81 artisan view:clear

if [ -f .env ] ; then
    php81 artisan migrate --force
    php81 artisan db:seed --force
fi
