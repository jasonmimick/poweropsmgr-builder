#!/bin/bash

# simple deploy for webroot from repo
WEB_ROOT=~/webroot
rm -rf "$WEB_ROOT"
cp -R ./webroot "$WEB_ROOT"
