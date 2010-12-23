set -e
#
# we are testing that resources declared in a class
# can be applied with an include statement
source lib/setup.sh
source lib/testlib.sh

OUTFILE=/tmp/class_param_use-$$
puppet apply <<PP | tee $OUTFILE
class x(\$y, \$z='2') {
  notice("\${y}-\${z}")
}
class {x: y => '1', z => '3'}
PP

file_contains $OUTFILE "1-3"
exit $?
