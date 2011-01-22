#!/bin/bash

source lib/testlib.sh

command=<<OUTPUT
echo "Hello, world!"
OUTPUT

output_contains echo "Hello, world!" "Hello"
echo $?

output_contains echo "Hello, world!" "world!"
echo $?

output_contains grep -l "ASLFKJ%" $0 $0
echo $?

output_contains echo "Hello, world!" "Goodbye"
echo $?

# this syntax is awful, but it appears to work
heredoc=$(
cat <<END
This is a heredoc.
END
)

output_contains echo "bob" $heredoc "heredoc"
echo $?

# EXPECTED RESULTS #
# "echo" output contained "Hello"
# 0
# "echo" output contained "world!"
# 0
# "grep" output contained "t/test_output_contains.sh"
# 0
# "echo" output did not contain "Goodbye"
# 10
# "echo" output contained "heredoc"
# 0
