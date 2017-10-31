#!/bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

WEBPID=$(ps -ef| grep SimpleHTTPServer | head -1 | awk '{print $2}')
sudo kill $WEBPID

# simple deploy for webroot from repo
WEB_ROOT=`readlink -f ~/webroot`
rm -rf "$WEB_ROOT"
cp -R "$SOURCE_DIR/webroot" "$WEB_ROOT"
echo "Kicking off build"
poweropsmgr-builder/poweropsmgr-builder.sh 3.4.7.479-1

echo "Start web-server"
pushd $WEB_ROOT
sudo nohup python -m SimpleHTTPServer 80 >/dev/null 2>&1 &
popd
