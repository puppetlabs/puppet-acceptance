set -e

source lib/setup.sh
source lib/testlib.sh

puppet apply --debug <<PP | tee /tmp/puppet-$$.log
user{ "root":
        ensure => "present",
}
PP

file_lacks created /tmp/puppet-$$.log

done_testing
