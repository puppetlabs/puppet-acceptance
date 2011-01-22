#!/bin/bash

source lib/setup.sh
source lib/testlib.sh

puppet resource host example.com ensure=present ip=127.0.0.1 target=/tmp/hosts-$$ --trace

file_contains /tmp/hosts-$$ 'example\.com'

done_testing
