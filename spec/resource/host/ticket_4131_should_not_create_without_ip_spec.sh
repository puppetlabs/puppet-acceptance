#!/bin/bash

set -e
set -u

source lib/setup.sh
source lib/testlib.sh

#
# precondition - entry doesn't exist
#
if [ -f /tmp/host-$$ ]; then
  rm /tmp/host-$$
fi

puppet resource host test1 ensure=present target="/tmp/host-$$" host_aliases=alias1 | tee /tmp/spec-$$.log

# post-condition - ip address not specified, create should fail with message.
file_contains /tmp/spec-$$.log 'ip is a required attribute for hosts'
exit $?
