#!/bin/sh
# Copyright 2019-2022 VMware, Inc.
# SPDX-License-Identifier: Apache-2

# shellcheck disable=SC1091,SC2006,SC2009,SC2154,SC2115,SC2164,SC2126,SC2035

PKGTOOLS=${PKGTOOLS:-/usr/libexec}

. "$PKGTOOLS/pkg_subr.sh"
. "$PKGTOOLS/pkg_sets.sh"

# ensure salt directory exists
mkdir -p /var/local/salt/etc

case $1 in
  mounted) if [ -d "$pkgsets/active/$PKG_BASENAME" ]; then
      backup_dir="/config/SaltBackup"
      backup_name="$PKG_BASENAME.tgz"
      echo "Backing up $PKG_BASENAME to $backup_dir/$backup_name"
      [ -d "$backup_dir" ] || mkdir -p "$backup_dir"
      /bin/rm -rf "$backup_dir/$backup_name"
      (cd "$pkgsets/active/$PKG_BASENAME"; tar zcf "$backup_dir/$backup_name" *)
      for f in /var/db/scripts/commit/salt.slax /var/db/scripts/op/salt_dualrengine.slax /var/db/scripts/event/salt_event.py /var/db/scripts/event/salt_log.slax; do
          echo "Removing old $DESTDIR$f"
          rm -f "$DESTDIR$f"
          echo "Copying $pkgsmnt/$PKG_BASENAME$f to $DESTDIR$f"
          cp -a "$pkgsmnt/$PKG_BASENAME$f" "$DESTDIR$f"
      done
    fi
    ;;
esac


## check script for issue where script is being run during boot
## cli (management daemon) not available till later  but
## salt will have already been installed in non-volatile space
## so not problematic to skip cli calls during boot.

mgd_avail=`ps aux | grep mgd | grep -v 'grep' | wc -l`
if [ "$mgd_avail" -ge "1" ]; then

## Management Daemon (cli) is available
## copy scripts to Dual routing engine if exists
cli <<!
edit
set system scripts op file salt_dualrengine.slax
commit
exit
!

cli -c "op salt_dualrengine"

## for commit script and event script
## for python event script - execute being superuser
cli <<!
edit
set system login user saltstack uid 2001
set system login user saltstack class super-user
set system login user saltstack authentication encrypted-password "salt@123"
set system scripts commit file salt.slax
set system scripts language python
set event-options generate-event E1 time-interval 60
set event-options policy SALT_POLICY events E1
set event-options policy SALT_POLICY then event-script salt_event.py
set event-options event-script file salt_event.py python-script-user saltstack
deactivate event-options policy SALT_POLICY
set event-options policy SALT_LOG_POLICY events SALT_LOG_ROTATE
set event-options policy SALT_LOG_POLICY then event-script salt_log.slax
set event-options event-script file salt_log.slax
set event-options generate-event SALT_LOG_ROTATE time-interval 180
commit
!

fi
