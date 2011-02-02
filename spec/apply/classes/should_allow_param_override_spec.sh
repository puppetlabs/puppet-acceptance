#!/bin/bash
set -u
set -e
#
# we are testing that resources declared in a class
# can be applied with an include statement
source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
class parent {
  notify { 'msg':
    message => parent,
  }
}
class child inherits parent {
  Notify['msg'] {message => 'child'}
}
include parent
include child
PP
)

manifest_output_contains $command "defined 'message' as 'child'"
done_testing
