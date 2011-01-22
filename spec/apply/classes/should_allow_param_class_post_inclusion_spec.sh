#!/bin/bash
#

set -u
set -e

# we are testing that resources declared in a class
# can be applied with an include statement
source lib/setup.sh
source lib/testlib.sh

OUTFILE=/tmp/class_param_use-$$
puppet apply <<PP | tee $OUTFILE
class x(\$y, \$z) {
  notice("\${y}-\${z}")
}
class {x: y => '1', z => '2'}
include x
PP

file_contains $OUTFILE "1-2"

done_testing
