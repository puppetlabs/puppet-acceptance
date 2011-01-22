#!/bin/bash
source lib/setup.sh
source lib/testlib.sh

command=$( cat <<PP
echo "notice 'Hello World'" | puppet apply
PP
)

output_contains $command 'notice:.*Hello World'

done_testing
