#!/bin/bash

POWEROPSMGR_BUILDER_VERSION=-0.0.1
#
set -e

MMS_VERSION=$1
echo "Starting MongoDB Ops Manager build for IBM Power"
echo "poweropsmgr-builder version: $POWEROPSMGR_BUILDER_VERSION"
echo "Building Ops Manager version: $MMS_VERSION"
DOWNLOAD_HOME=https://downloads.mongodb.com/on-prem-mms/tar/
BUILD_HOME="`pwd`/builds/"
echo "Build home: $BUILD_HOME"

[ -d $BUILD_HOME ] || mkdir -p $BUILD_HOME

BUILD_DIR="$BUILD_HOME$MMS_VERSION"
echo "Build directory: $BUILD_DIR"
BUILD_WORKING_DIR="$BUILD_DIR/working"
echo "Build working directory: $BUILD_WORKING_DIR"
mkdir -p $BUILD_WORKING_DIR
cd $BUILD_WORKING_DIR
echo "Working in `pwd`"
MMS_TAR="mongodb-mms-$MMS_VERSION.x86_64.tar.gz"
MMS_TAR_DIR="mongodb-mms-$MMS_VERSION.x86_64"
MMS_POWER_TAR="mongodb-mms-$MMS_VERSION.ppc64le.tar.gz"
echo "Attemping download of $DOWNLOAD_HOME$MMS_TAR to $BUILD_DIR/working"
curl -OL $DOWNLOAD_HOME$MMS_TAR
echo "Download complete."
echo "Unpacking Ops Manager build: $MMS_TAR"
tar zxf $MMS_TAR
echo "Unpack complete."

#edit conf

#echo conf/mms.conf
# -!! Location of JDK is POST INSTALL step!!
#JAVA_HOME to the location of a Power build of the JDK
#    JAVA_MMS_UI_OPTS change -Xss228k to -Xss328k
sed -i 's/Xss228k/Xss328k/' $MMS_TAR_DIR/conf/mms.conf
#edit conf/conf-mms.properties
#set 
#mongodb.release.directory=<path?> --- POST INSTALL STEP!!
#mongodb.release.autoDownload=false
cat << CONF_DOC_NOTES >> $MMS_TAR_DIR/conf/conf-mms.properties
# ####################################
# Settings for MongoDB Ops Manager on IBM POWER

mongodb.release.autoDownload=false

# poweropsmgr-builder.sh Version: $POWEROPSMGR_BUILDER_VERSION
# Build timestamp: `date` 
CONF_DOC_NOTES


#pack up
tar czf ../$MMS_POWER_TAR $MMS_TAR_DIR

cd ..
echo "Created `pwd`/$MMS_POWER_TAR" 

#create MongoDB versions for Ops Mgr (if needed).
# when testing - we need to check this, maybe because we have
# the right platform of the archive now it will 'just work'
# that would be sweet


#deploy to file server

