#!/bin/bash

source lib/testlib.sh

file_contains "NOT_A_FILE" "irrelevant"
echo $?
file_contains "README" "kumquat"
echo $?
file_contains "README" "WARNING"
echo $?

# EXPECTED RESULTS #
# File NOT_A_FILE not found
# 10
# README does not contain "kumquat"
# 10
# README contains "WARNING"
# 0
