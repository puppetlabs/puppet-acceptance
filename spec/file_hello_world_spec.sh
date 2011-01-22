#!/bin/bash

set -u
source lib/setup.sh
source lib/testlib.sh
set -e

execute_manifest <<PP
file{'/tmp/hello.$$.txt': content => 'hello world'}
PP

file_contains /tmp/hello.$$.txt 'hello world'

done_testing
