#!/bin/bash
set -u
set -e

source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
if( 1 == 3) {
  notice('if')
} elsif(2 == 2) {
  notice('elsif')
} else {
  notice('else')
}
PP
)

manifest_output_contains $command 'elsif'
done_testing
