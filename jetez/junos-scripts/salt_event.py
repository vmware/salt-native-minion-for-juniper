#!/usr/bin/python
# Copyright 2019-2022 VMware, Inc.
# SPDX-License-Identifier: Apache-2

import jcs
import glob
from jnpr.junos import Device
from jnpr.junos.utils.config import Config
data = """
activate system extensions extension-service
deactivate event-options policy SALT_POLICY
"""
def main():
    with Device() as dev:
        dev.timeout = 300
        check_mnt_path = (glob.glob("/packages/sets/active/*salt-junos*"))
        check_cnf_path = (glob.glob("/config/SaltBackup/*.tgz"))
        jcs.trace("salt: Inside main");
        jcs.trace("salt: mnt"+str(check_mnt_path));
        jcs.trace("salt: cnf"+str(check_cnf_path));
        # Check mount salt package is not exist and salt backup package present
        if len(check_cnf_path) != 0 and len(check_mnt_path) == 0:
            jcs.trace("salt: Installing the package");
            # Install the package
            dev.rpc.request_package_add(package_name=check_cnf_path[0])
            with Config(dev) as cu:
                cu.load(data, format='set')
                if cu.commit_check():
                    jcs.trace("salt: commit check successful");
                    cu.commit(timeout=360)
        else:
            jcs.trace("Salt: Not Installed");
if __name__ == '__main__':
    jcs.trace("Salt: main");
    main()
