#!/bin/bash
#
# ensure that undefined variables evaluate as false
#

set -e
set -u

source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
if \$undef_var {
} else {
  notice('undef')
}
PP
)

manifest_output_contains $command 'undef'
done_testing
