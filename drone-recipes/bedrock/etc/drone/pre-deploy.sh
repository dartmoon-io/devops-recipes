#!/usr/bin/env bash

cd $DEPLOY_PATH

mkdir -p website/web
rm -rf public_html
ln -s website/web public_html
