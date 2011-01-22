#!/bin/bash

source lib/testlib.sh

file_exists "README"
echo $?
file_exists "IGNOREME"
echo $?
file_exists "t/test_file_exists.sh"
echo $?
file_exists "t/test_pancake_exists.sh"
echo $?

TESTFILE="README"
file_exists $TESTFILE
echo $?

TESTFILE="IGNOREME"
file_exists $TESTFILE
echo $?

done_testing

# EXPECTED RESULTS #
# README exists
# 0
# IGNOREME does not exist
# 10
# t/test_file_exists.sh exists
# 0
# t/test_pancake_exists.sh does not exist
# 10
# README exists
# 0
# IGNOREME does not exist
# 10
