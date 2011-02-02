set -e

source lib/setup.sh
source lib/testlib.sh

# hash reassignment should fail

command=$( cat <<PP
\$my_hash = {'one' => '1', 'two' => '2' }
\$my_hash['one']='1.5'
PP
)

manifest_output_lacks $command \
    "Assigning to the hash 'my_hash' with an existing key 'one'"
done_testing
