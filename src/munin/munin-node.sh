#!/bin/sh
#
# This is a *VERY* simple munin-node server that is written for the busybox
# msh shell and designed to be run under inet.
#
# There is VERY LITTLE input validation. 
#
# Author: Darryl Ross (spam@afoyi.com)
# Version: $Id$
# Copyright: Copyright (c) 2007 Darryl Ross
#
# Modified by David Rowe May 2008 for busybox msh shell
 
PLUGINPATH=/etc/munin/plugins

echo "# munin node at `hostname`"
while read INPUT; do

        # remove any non-alpha characters and parse command line

	INPUT=`echo ${INPUT} | sed -e 's/[^a-zA-Z0-9_ ]//g'`
	CMD=`echo ${INPUT} | awk '{ print $1 }'`
	CMDNAME=`echo ${INPUT} | awk '{ print $2 }'`

	case ${CMD} in

		list)
			PLUGINS=`cd $PLUGINPATH && ls`
			for PLUGIN in ${PLUGINS}; do
				echo -n "${PLUGIN} "
			done
			echo
			;;
		nodes)
			hostname
			echo .
			;;

		config)
			${PLUGINPATH}/${CMDNAME} config
			echo .
			;;
		fetch)
			${PLUGINPATH}/${CMDNAME}
			echo .
			;;
	
		version)
			echo "munins node on `hostname` version: DR_0.0.1"
			;;

		quit)
			exit 1
			;;

		*)
			echo "# Unknown command. Try list, nodes, config, fetch, version or quit"
			;;
	esac

done
