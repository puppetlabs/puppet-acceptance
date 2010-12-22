#!/bin/bash

# raise error on unbound variables
set -u

# get the constants
source lib/setup.sh

# tests that a file contains a string
# takes the name of the file as $1
# takes the string which the file should contain as $2
# returns the exit code for OK or FAILURE
file_contains() {
    local filename=$1
    local expected=$2

    if [ -e "$filename" ]; then
        grep -q $expected $filename > /dev/null
        if [ $? = 0 ]; then
            pass "$filename contains \"$expected\""
        else
            fail "$filename does not contain \"$expected\""
        fi
    else
        fail "File $filename not found"
    fi
}

# passes a test and sets $? to mark the success
# takes a description
pass()
{
    echo $1
    return $EXIT_OK
}

# fails a test and sets $? to mark the failure
# takes a description
fail()
{
    echo $1
    return $EXIT_FAILURE
}
