#!/bin/bash

source spec/drivers.sh
driver_master_and_agent_locally

source lib/setup.sh
source lib/testlib.sh

execute_manifest <<PP
file{'/tmp/hello.$$.txt': content => 'hello world'}
PP

file_contains 'hello world' /tmp/hello.$$.txt
exit $?
