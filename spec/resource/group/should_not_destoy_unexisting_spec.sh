#!/bin/bash

set -e
set -u

# PRECONDITION
source local_setup.sh
source lib/testlib.sh

GROUP=bozo$$ 
if getent group $GROUP; then
  groupdel bozo
fi

# TEST
$BIN/puppet resource group $GROUP ensure=absent > $OUTFILE

# VALIDATE
file_lacks $OUTFILE "notice: /Group[$GROUP]/ensure: removed"

done_testing
