#!/bin/bash
set -u
set -e
source lib/setup.sh
source lib/testlib.sh

# test that resource declared in classes are not applied without include
command=$( cat <<PP
class x {
  notify{'NEVER':}
}
PP
)

# postcondition - test that the file is empty
# this assumes that we are running at notice level (not debug or verbose)
manifest_output_lacks $command 'NEVER'
done_testing
