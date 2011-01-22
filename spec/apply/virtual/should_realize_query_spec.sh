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
  host_aliases => 'alias',
  ensure=>present,
}
Host<| ip=='127.0.0.2' |>
PP

file_contains $HOSTFILE test$$

done_testing
