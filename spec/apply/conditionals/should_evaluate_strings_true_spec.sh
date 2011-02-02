#!/bin/bash
#
#  test that the string 'false' evaluates to true
#
source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
if 'false' {
  notice('true')
} else {
  notice('false')
}
PP
)

manifest_output_contains $command 'true'
done_testing
