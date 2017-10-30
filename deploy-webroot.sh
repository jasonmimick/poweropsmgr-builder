#!/bin/bash

WEBPID=$(ps -ef| grep SimpleHTTPServer | head -1 | awk '{print $2}')
sudo kill $WEBPID

# simple deploy for webroot from repo
WEB_ROOT=~/webroot
rm -rf "$WEB_ROOT"
cp -R ./webroot "$WEB_ROOT"
sudo nohup python -m SimpleHTTPServer 80 &

