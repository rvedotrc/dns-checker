#!/bin/bash
set -eu
./dns-dependency-walker "$@"
make -f ~/git/github.com/rvedotrc/awsdot/Makefile-for-dot
