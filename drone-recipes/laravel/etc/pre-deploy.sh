#!/usr/bin/env bash

cd $DEPLOY_PATH

mkdir -p website/public
rm -rf public_html
ln -s website/public public_html
