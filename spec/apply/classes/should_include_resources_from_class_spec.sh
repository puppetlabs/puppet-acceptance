#!/bin/bash
set -u
set -e
# we are testing that resources declared in a class
# can be applied with an include statement
source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
class x {
  notify{'a':}
}
include x
PP
)

manifest_output_contains $command "defined 'message' as 'a'"
done_testing
