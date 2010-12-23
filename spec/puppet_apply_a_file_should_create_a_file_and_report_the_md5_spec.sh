set -e

source lib/setup.sh
source lib/testlib.sh

rm -f /tmp/hello.world.$$.txt

puppet apply <<PP | grep "defined content as '{md5}098f6bcd4621d373cade4e832627b4f6'"
file{ "/tmp/hello.world.$$.txt":
        content => "test",
}
PP


# the original test used -f; does -e suffice?
file_exists /tmp/hello.world.$$.txt
exit $?
