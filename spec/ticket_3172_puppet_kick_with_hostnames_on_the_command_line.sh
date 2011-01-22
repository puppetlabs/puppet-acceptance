#!/bin/bash

source lib/setup.sh
source lib/testlib.sh

puppet kick hostname1 | tee /tmp/puppet-kick-$$.txt

file_contains /tmp/puppet-kick-$$.txt "Triggering hostname1"

done_testing
