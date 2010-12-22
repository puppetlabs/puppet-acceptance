#!/bin/bash

set -u
source lib/setup.sh
source lib/testlib.sh
set -e

execute_manifest <<PP
file{'/tmp/hello.$$.txt': content => 'hello world'}
PP

file_contains 'hello world' /tmp/hello.$$.txt
exit $?
