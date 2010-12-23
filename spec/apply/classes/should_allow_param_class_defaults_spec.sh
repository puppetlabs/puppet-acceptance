#!/bin/bash

set -e
set -u

# we are testing that resources declared in a class
# can be applied with an include statement
source lib/setup.sh
source lib/testlib.sh

OUTFILE=/tmp/class_param_use-$$
puppet apply <<PP | tee $OUTFILE
class x(\$y, \$z='2') {
  notice("\${y}-\${z}")
}
class {x: y => '1'}
PP

file_contains $OUTFILE "1-2"
exit $?
