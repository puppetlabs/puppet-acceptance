#!/bin/bash
source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
if '' {
} else {
  notice('empty')
}
PP
)

manifest_output_contains $command 'empty'
done_testing
