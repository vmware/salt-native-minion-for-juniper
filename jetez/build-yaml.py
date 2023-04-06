#!/usr/bin/env python3
# Copyright 2019-2022 VMware, Inc.
# SPDX-License-Identifier: Apache-2


import sys
import datetime
import os
from ruamel.yaml import YAML

version = "VERSION_TO_BE_REPLACED"
year = datetime.datetime.now().strftime("%Y")
yaml = YAML()

jetconfig = {
    "basename": "salt-junos",
    "comment": f"Salt Minion {version} for JUNOS",
    "copyright": f"Copyright {year}, YOUR-NAME or COMPANY NAME",
    "arch": "x86",
    "abi": "64",
    "scripts": "actions.sh",
    "actions": "mounted",
    "mountlate": True,
    "files": [],
}


def get_files(start_dir):

    filelist = []
    with os.scandir(path=start_dir) as dirgen:
        for d in dirgen:
            if d.is_dir():
                filelist.extend(get_files(d.path))
            else:
                filelist.append(d.path)
    return filelist


for f in get_files("salt-junos"):
    basename = f[11:]
    if basename.endswith(jetconfig["scripts"]):
        continue

    item = {"source": basename, "destination": f"/var/db/scripts/jet/{basename}"}
    jetconfig["files"].append(item)

with open("junos-scripts.yaml", "r") as extra:
    extra_stuff = yaml.load(extra)

jetconfig['files'].extend(extra_stuff['files'])

with open("salt-junos.yaml", "w") as f:
    yaml.dump(jetconfig, f)
