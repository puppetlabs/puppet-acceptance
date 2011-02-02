#!/bin/bash

source lib/setup.sh
source lib/testlib.sh

output_contains "puppet doc -r function" 'Function Reference'
done_testing
