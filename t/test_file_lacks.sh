#!/bin/bash

source lib/testlib.sh

file_lacks "NOT_A_FILE" "irrelevant"
echo $?
file_lacks "README" "kumquat"
echo $?
file_lacks "README" "WARNING"
echo $?

done_testing

# EXPECTED RESULTS #
# File NOT_A_FILE not found
# 10
# README should not contain "kumquat"
# 0
# README contains "WARNING"
# 10
