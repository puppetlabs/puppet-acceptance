#!/bin/bash
#
#  test that false evaluates to false
#
source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
if false {
} else {
  notice('false')
}
PP
)

manifest_output_contains $command 'false'
done_testing
