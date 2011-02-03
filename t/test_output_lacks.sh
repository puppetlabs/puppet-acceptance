#!/bin/bash

source lib/testlib.sh

command=<<OUTPUT
echo "Hello, world!"
OUTPUT

output_lacks echo "Hello, world!" "Goodbye"
echo $?

output_lacks echo "Hello, world!" "world!"
echo $?

output_lacks grep -l "ASLFKJ%" $0 $0
echo $?

# this syntax is awful, but it appears to work
heredoc=$(
cat <<END
This is a heredoc.
END
)

output_lacks echo "bob" $heredoc "wheredoc"
echo $?

output_lacks echo "bob" $heredoc "heredoc"
echo $?

done_testing

# EXPECTED RESULTS #
# "echo" output did not contain "Goodbye"
# 0
# "echo" output contained "world!"
# 10
# "grep" output contained "t/test_output_lacks.sh"
# 10
# "echo" output did not contain "wheredoc"
# 0
# "echo" output contained "heredoc"
# 10
