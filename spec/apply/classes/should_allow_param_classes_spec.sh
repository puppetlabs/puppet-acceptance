#!/bin/bash
set -u
set -e
# we are testing that resources declared in a class
# can be applied with an include statement
source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
class x(\$y, \$z) {
  notice("\${y}-\${z}")
}
class {x: y => '1', z => '2'}
PP
)

manifest_output_contains $command "1-2"
done_testing
