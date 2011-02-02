#!/bin/bash

source lib/testlib.sh

# this syntax is awful, but it appears to work
command=$( cat <<OUTPUT
notify {'Hello, world!':}
OUTPUT
)

manifest_output_lacks $command "Goodbye, world!"
echo $?

manifest_output_lacks $command "Hello, world!"
echo $?

done_testing

# EXPECTED RESULTS #
# manifest output for "notify" did not contain "Goodbye, world!"
# 0
# manifest output for "notify" contained "Hello, world!"
# notify {'Hello, world!':}
# notice: Hello, world!
# notice: /Stage[main]//Notify[Hello, world!]/message: defined 'message' as 'Hello, world!'
# 10
