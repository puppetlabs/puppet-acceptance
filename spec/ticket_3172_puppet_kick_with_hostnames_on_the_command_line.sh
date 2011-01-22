#!/bin/bash

source lib/setup.sh
source lib/testlib.sh

puppet kick hostname1 | tee /tmp/puppet-kick-$$.txt

file_contains "Triggering hostname1" /tmp/puppet-kick-$$.txt

done_testing
