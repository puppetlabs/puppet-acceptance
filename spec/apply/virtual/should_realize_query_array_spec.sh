set -e

source lib/setup.sh
source lib/testlib.sh

HOSTFILE=/tmp/hosts-$$
# precondition:
# /tmp/hosts-$$ should not exist
if [ -e $HOSTFILE ]; then
  rm $HOSTFILE
fi

puppet apply <<PP
@host { 'test$$': 
  ip=>'127.0.0.2', 
  target=>'$HOSTFILE', 
  host_aliases => ['one', 'two', 'three'],
  ensure=>present,
}
Host<| host_aliases=='two' |>
PP

file_contains $HOSTFILE test$$

done_testing
