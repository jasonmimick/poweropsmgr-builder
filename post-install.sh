#!/bin/bash
#
# MongoDB Ops Manager for IBM POWER
# post-install.sh
#
# This script should be run after unpacking
# the Ops Manager archive and _before_ starting
# Ops Manager.
#
# The script will:
# (1) Set the JAVA_HOME property for Ops Manager
#     to a suitable IBM POWER JDK installation.
# (2) Optionally, set the Version Manager Local 
#     Download folder (autmation.versions.directory)
#     property.
#
#  ALPHA VERSION
#  jason.mimick@mongodb.com
#
#
set -e
REQUIRED_JDK_VERSION="1.8.0"

# return 1 for success, Ops Mgr NOT FOUND
# return 0 for failure, Ops Mgr FOUND
ops_mgr_not_installed() {
	local mms_conf
	mms_conf="$1/conf/mms.conf"
	echo "check_ops_mgr_install check existence of $mms_conf"
	if [ -e "$mms_conf" ]; then
		return 1		#non-zero, failure
	else
		return 0		#Success
	fi
}


# Credit for generic yes/no question
# https://gist.github.com/davejamesmiller/1965569
ask() {
    # https://djm.me/ask
    local prompt default reply

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

echo "MongoDB Ops Manager for IBM POWER"
echo "Post-Installation script"
echo ""
echo "Required JDK version=$REQUIRED_JDK_VERSION"
echo ""
echo "Detecting Ops Manager for IBM POWER installation"
MMS_INSTALL_DIR="`pwd`/mongodb-mms-3.4.7.479-1.ppc64le"
echo "Looking in: $MMS_INSTALL_DIR"
if ops_mgr_not_installed "$MMS_INSTALL_DIR"; then
	echo "Did not find Ops Manager installed to $MMS_INSTALL_DIR."
	echo -n "Enter path to Ops Manager installation: "
	read new_install_dir </dev/tty
	echo "new_install_dir=$new_install_dir"
	if ops_mgr_not_installed "$new_install_dir"; then
		echo ""
		echo "Sorry Ops Manager not detected in path $new_install_dir"
		echo "Please re-run post-install.sh"
		exit 1
	else
		MMS_INSTALL_DIR="$new_install_dir"
		echo ">>>>> MMS_INSTALL_DIR=$MMS_INSTALL_DIR"
	fi
fi
JAVAC=`which javac`
# blow up if no javac => no JDK installed!
JAVA_HOME=`readlink -f $JAVAC | cut -d '/' -f 1-5`
if ask "(1) Override detected JAVA_HOME=$JAVA_HOME?" N; then
	echo -n "Enter new JAVA_HOME:"
	read JAVA_HOME </dev/tty
	if ! [ -d $JAVA_HOME ]; then
		echo ""
		echo "Path $JAVA_HOME does not exist"
		exit 1
	fi
else
	echo "Will not override detected JAVA_HOME"
fi

echo ""
echo "(2) Validating JDK version is $REQUIRED_JDK_VERSION"
JDK_VERSION=$($JAVA_HOME/bin/javac -version 2>&1)
JDK_VERSION=`echo $JDK_VERSION | cut -d ' ' -f 2 | cut -d '_' -f 1`

if [ ! "$JDK_VERSION" = "$REQUIRED_JDK_VERSION" ]; then
	echo "Invalid JDK version detected. Found:$JDK_VERSION"
	echo "Please install correct JDK and re-run post-install.sh"
	exit 1
fi
echo "Found JDK version: $JDK_VERSION"
echo ""

# Validate JCE - Java Cryptography Extensions is installed
echo "Validating JCE - Java Cryptography Extensions are installed."
GOT_JCE=`$JAVA_HOME/bin/jrunscript -e 'print (javax.crypto.Cipher.getMaxAllowedKeyLength("RC5") >= 256);'`
if [ "$GOT_JCE" = "true" ]; then
	echo "JCE - Java Cryptography Extensions verified."
else
	echo "Unable to validate JCE - Java Cryptography Extenstion."
	echo "Please resolve and re-run post-install.sh"
	exit 1
fi
echo ""
if ask "(3) Do you wish to override the Ops Manager Versions Directory?" N; then
	echo -n "Enter new automation.versions.directory: "
	read automation_versions_directory </dev/tty
	if [ ! -d "$automation_versions_directory" ]; then
		echo ""
		echo "Sorry, path $automation_versions_directory does not exit."
		echo "Re-run post-install.sh"
		exit 1
	fi
	OVERRIDE_AUTOMATION_VERSIONS_DIRECTORY=1
	FOO=1
else
	echo "Will not override Ops Manager Versions Directory"
	OVERRIDE_AUTOMATION_VERSIONS_DIRECTORY=0
	FOO=0
fi 

echo " Post Install Summary:"
echo " ************************************************** "
echo ""
echo "OVERRIDE_AUTOMATION_VERSIONS_DIRECTORY=$OVERRIDE_AUTOMATION_VERSIONS_DIRECTORY"
echo "Using JAVA_HOME=$JAVA_HOME"
if (($OVERRIDE_AUTOMATION_VERSIONS_DIRECTORY)); then 
	echo "Using automation_versions_directory=$automation_versions_directory"
fi
echo ""
echo " ************************************************** "
echo ""
if ask "* Do you wish to write updated Ops Manager configuration?" N; then
	echo "Updating $MMS_INSTALL_DIR/conf/mms.conf ......"
	cat << MMS_CONF >> $MMS_INSTALL_DIR/conf/mms.conf
# 
#
# #####################################
# Settings for MongoDB Ops Manager on IBM POWER
# post-install.sh update: `date`
JAVA_HOME=$JAVA_HOME
APP_NAME=java
#
# #####################################
MMS_CONF
	echo "Update complete."
	if (($OVERRIDE_AUTOMATION_VERSIONS_DIRECTORY)); then 
		echo "Updating $MMS_INSTALL_DIR/conf/conf-mms.properties ......"
		echo "Using automation_versions_directory=$automation_versions_directory"
		cat << CONF_MMS_PROPERTIES >> $MMS_INSTALL_DIR/conf/conf-mms.properties
# 
#
# #####################################
# Settings for MongoDB Ops Manager on IBM POWER
# post-install.sh update: `date`
automation.versions.directory=$automation_versions_directory
#
# #####################################
CONF_MMS_PROPERTIES
	echo "Update complete."
	fi
else
	echo "Configuration not updated"
fi


echo "MongoDB Ops Manager for IBM POWER Post Installation Complete."
echo "Please continue with documented Ops Manager installation steps."
exit 0




