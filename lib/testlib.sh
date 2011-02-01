#!/bin/bash

# raise error on unbound variables
set -u

# get the constants
source lib/setup.sh

TEST_LIB_EXIT_CODE=$EXIT_OK

# tests that a file contains a string
# takes the name of the file as $1
# takes the string which the file should contain as $2
# returns the exit code for OK or FAILURE
file_contains() {
    local filename=$1
    local expected=$2

    if [ ! -e "$filename" ]; then
        fail "File $filename not found"
    else
        if grep -q $expected $filename > /dev/null; then
            pass "$filename contains \"$expected\""
        else
            fail "$filename does not contain \"$expected\""
        fi
    fi
}

# tests that a file does not contain a string
# takes the name of the file as $1
# takes the string which the file should contain as $2
# returns the exit code for OK or FAILURE
file_lacks() {
    local filename=$1
    local expected=$2

    if [ ! -e "$filename" ]; then
        fail "File $filename not found"
    else
        if grep -q $expected $filename > /dev/null; then
            fail "$filename contains \"$expected\""
        else
            pass "$filename should not contain \"$expected\""
        fi
    fi
}

# tests that a given file exists
# takes the name of the file
file_exists()
{
    local filename=$1
    if [ -e $filename ]; then
        pass "$filename exists"
    else
        fail "$filename does not exist"
    fi
}

# tests that the output of a command contains a string
# takes the command
# takes the string to find
output_contains()
{
    local last_index=$#
    local penult_index=$(($last_index - 1))
    local command=${@:1:$penult_index}
    local expected=${@:$last_index:1}

    if eval $command | grep -q "$expected" > /dev/null; then
        pass "\"$1\" output contained \"$expected\""
    else
        fail "\"$1\" output did not contain \"$expected\""
    fi
}

# tests that the output of applying a manifest contains a string
# takes the manifest
# takes a string
manifest_output_contains()
{
    local last_index=$#
    local penult_index=$(($last_index - 1))
    local command=${@:1:$penult_index}
    local expected=${@:$last_index:1}
    local output=$(manifest_apply "$command")

    if echo $output | grep -q "$expected" > /dev/null; then
        pass "manifest output for \"$1\" contained \"$expected\""
    else
        fail "manifest output for \"$1\" did not contain \"$expected\""
    fi
}

# tests that the output of applying a manifest does not contain a string
# takes the manifest
# takes a string
manifest_output_lacks()
{
    local last_index=$#
    local penult_index=$(($last_index - 1))
    local command=${@:1:$penult_index}
    local expected=${@:$last_index:1}
    local output=$(manifest_apply "$command")

    if echo $output | grep -q "$expected" > /dev/null; then
        fail "manifest output for \"$1\" contained \"$expected\""
    else
        pass "manifest output for \"$1\" did not contain \"$expected\""
    fi
}

# helper function to execute a manifest
manifest_apply()
{
    local confdir="/tmp/puppet-$$-standalone"

    mkdir -p "$confdir/manifests"

    echo "$1" | puppet apply --confdir $confdir \
      --manifestdir "$confdir/manifests" --modulepath "$confdir/modules" \
      --color false
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
    TEST_LIB_EXIT_CODE=$EXIT_FAILURE
    return $EXIT_FAILURE
}


done_testing()
{
    exit $TEST_LIB_EXIT_CODE
}
