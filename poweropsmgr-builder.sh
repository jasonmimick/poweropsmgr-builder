#!/bin/bash

POWEROPSMGR_BUILDER_VERSION=-0.0.1
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_JDK_DIR=$SOURCE_DIR
TARGET_JDK_TGZ="jdk.ppc64le.tgz"
#
set -e

MMS_VERSION=$1
echo "Starting MongoDB Ops Manager build for IBM Power"
echo "poweropsmgr-builder version: $POWEROPSMGR_BUILDER_VERSION"
echo "Building Ops Manager version: $MMS_VERSION"
echo "Source directory: $SOURCE_DIR"
DOWNLOAD_HOME=https://downloads.mongodb.com/on-prem-mms/tar/
#DOWNLOAD_HOME=http://172.31.49.71/local_opsmgr_archives/
BUILD_HOME="/home/ec2-user/webroot/builds/"
echo "Build home: $BUILD_HOME"

[ -d $BUILD_HOME ] || mkdir -p $BUILD_HOME

BUILD_DIR="$BUILD_HOME$MMS_VERSION"
echo "Build directory: $BUILD_DIR"
echo "Cleaning build directory: $BUILD_DIR"
rm -rf $BUILD_DIR
BUILD_WORKING_DIR="$BUILD_DIR/working"
echo "Build working directory: $BUILD_WORKING_DIR"
mkdir -p $BUILD_WORKING_DIR
cd $BUILD_WORKING_DIR
echo "Working in: `pwd`"
MMS_TAR="mongodb-mms-$MMS_VERSION.x86_64.tar.gz"
MMS_TAR_DIR="mongodb-mms-$MMS_VERSION.x86_64"
MMS_POWER_TAR="mongodb-mms-$MMS_VERSION.ppc64le.tar.gz"
echo "Attemping download of $DOWNLOAD_HOME$MMS_TAR to $BUILD_WORKING_DIR"
curl -OL $DOWNLOAD_HOME$MMS_TAR
echo "Download complete."
echo "Unpacking Ops Manager build: `pwd`/$MMS_TAR"
tar zxf $MMS_TAR
echo "Unpack complete."

#edit conf

echo "Updating JVM settings `pwd`/$MMS_TAR_DIR/conf/mms.conf ......"
sed -i 's/Xss228k/Xss328k/' $MMS_TAR_DIR/conf/mms.conf
echo "JVM settings update complete: `pwd`/$MMS_TAR_DIR/conf/mms.conf"
echo ""

echo "Updating APP_NAME in `pwd`/$MMS_TAR_DIR/conf/mms.conf ......"
cat << MMS_CONF >> $MMS_TAR_DIR/conf/mms.conf
# 
#
# #####################################
# Settings for MongoDB Ops Manager on IBM POWER
# post-install.sh update: `date`
APP_NAME=java
#
# #####################################
MMS_CONF
echo "APP_NAME update complete: `pwd`/$MMS_TAR_DIR/conf/mms.conf"
echo ""

echo "Updating `pwd`/$MMS_TAR_DIR/conf/conf-mms.properties ......"
cat << CONF_DOC_NOTES >> $MMS_TAR_DIR/conf/conf-mms.properties
#
# #####################################
# Settings for MongoDB Ops Manager on IBM POWER

mongodb.release.autoDownload=false

# poweropsmgr-builder.sh Version: $POWEROPSMGR_BUILDER_VERSION
# Build timestamp: `date` 
#
# #####################################
#
CONF_DOC_NOTES
echo "Update complete: `pwd`/$MMS_TAR_DIR/conf/conf-mms.properties"
echo ""

#overrite jdk with $SOURCE_JDK_DIR/$TARGET_JDK_TGZ jdk
MMS_JDK_DIR=`readlink -f $MMS_TAR_DIR/jdk`
echo "Removing bundled JDK:$MMS_JDK_DIR"
rm -rf $MMS_JDK_DIR
mkdir -p $MMS_JDK_DIR

echo "Copying $SOURCE_JDK_DIR/$TARGET_JDK_TGZ to $MMS_JDK_DIR"
cp $SOURCE_JDK_DIR/$TARGET_JDK_TGZ $MMS_JDK_DIR
ls -l $MMS_JDK_DIR

pushd $MMS_JDK_DIR
echo "Unpacking $TARGET_JDK_TGZ in `pwd`"
tar xzvf $TARGET_JDK_TGZ
echo "Cleaning up $TARGET_JDK_TGZ in `pwd`"
popd
ls -l $MMS_JDK_DIR

#pack up
MMS_POWER_TAR_DIR=$(sed 's/x86_64/ppc64le/g' <<< $MMS_TAR_DIR)
mv $MMS_TAR_DIR $MMS_POWER_TAR_DIR
echo "Creating archive $MMS_POWER_TAR from $MMS_POWER_TAR_DIR"
tar czf ../$MMS_POWER_TAR $MMS_POWER_TAR_DIR

cd ..
echo "Created `pwd`/$MMS_POWER_TAR" 

#create MongoDB versions for Ops Mgr (if needed).
# when testing - we need to check this, maybe because we have
# the right platform of the archive now it will 'just work'
# that would be sweet


# clean up
#rm -rf $BUILD_WORKING_DIR 

echo "poweropsmgr-builder.sh complete."
