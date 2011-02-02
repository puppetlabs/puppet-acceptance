#!/bin/bash
set -u
set -e
source lib/setup.sh
source lib/testlib.sh

# test that else clause will be reached
# if no expressions match
command=$( cat <<PP
if( 1 == 2) {
  notice('if')
} elsif(2 == 3) {
  notice('elsif')
} else {
  notice('else')
}
PP
)

manifest_output_contains $command 'else'
done_testing
