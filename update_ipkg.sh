#!/bin/sh
# ipdate_ipkg.sh
# David Rowe 9 Feb 2008
#
# Helper script to upload a new (or modified) ipkg and update the
# Packages file.  

# Customise this line for your upload program/script
FTP=/home/david/web/ftp.tcl

# Work out which repository we should upload to by scraping etc/ipkg.conf
REP=`cat uClinux-dist/root/etc/ipkg.conf | grep snapshots | sed -e "s|.*http://rowetel.com/ucasterisk/ipkg\(.*\)|\1|" `

# Path to ipkgs on your web server, should match URL in /etc/ipkg.conf
IPKG_PATH=ucasterisk/ipkg$REP

if [ $# -ne 1 ]; then
  echo "usage $0 ipkgName"
  echo "e.g. $0 ipkg/ntp_4.1.1-1_bfin.ipk"
  exit 0
fi

# Update and upload Packages file, which is index of all packages.
# Note we assume that all packages are built and present in the ipkg
# directory

cd ipkg
../scripts/ipkg-make-index.sh . > Packages
$FTP Packages $IPKG_PATH

# Upload ipkg

IPKG=`basename $1`
$FTP $IPKG $IPKG_PATH

