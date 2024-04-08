#!/usr/bin/env python3

# Copyright (c) 2018-2019, Ulf Magnusson
# SPDX-License-Identifier: ISC

"""
Updates an old .config file or creates a new one, by filling in default values
for all new symbols. This is the same as picking the default selection for all
symbols in oldconfig, or entering the menuconfig interface and immediately
saving as autoconfig.h file.

The default input/output filename is '.config'. A different filename can be
passed in the KCONFIG_CONFIG environment variable.

"""
import kconfiglib


def main():
    kconf = kconfiglib.standard_kconfig(__doc__)
    print(kconf.load_config())
    print(kconf.write_autoconf())


if __name__ == "__main__":
    main()
