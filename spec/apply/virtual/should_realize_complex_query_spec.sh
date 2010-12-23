#!/bin/bash
#
#
#
#
set -e
set -u

source lib/setup.sh
source lib/testlib.sh

HOSTFILE=/tmp/hosts-$$
# precondition:
# /tmp/hosts-$$ should not exist
if [ -e $HOSTFILE ]; then
  rm $HOSTFILE
fi

puppet apply <<PP
@host { 'test$$1': 
  ip=>'127.0.0.2', 
  target=>'$HOSTFILE', 
  host_aliases => ['one', 'two', 'three'],
  ensure=>present,
}
@host { 'test$$2': 
  ip=>'127.0.0.3', 
  target=>'$HOSTFILE', 
  host_aliases => 'two',
  ensure=>present,
}
Host<| host_aliases=='two' and ip=='127.0.0.3' |>
PP

file_contains $HOSTFILE test$$2
exit $?
