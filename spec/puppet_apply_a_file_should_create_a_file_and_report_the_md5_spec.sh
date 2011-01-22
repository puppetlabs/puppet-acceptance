set -e

source lib/setup.sh
source lib/testlib.sh

rm -f /tmp/hello.world.$$.txt

rule=$( cat <<PP
file{ "/tmp/hello.world.$$.txt":
        content => "test",
}
PP
)

output_contains puppet apply $rule "defined content as '{md5}098f6bcd4621d373cade4e832627b4f6'"

# the original test used -f; does -e suffice?
file_exists /tmp/hello.world.$$.txt

done_testing
