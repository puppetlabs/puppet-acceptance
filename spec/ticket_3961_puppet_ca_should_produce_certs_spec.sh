#!/bin/bash

source lib/setup.sh

# Using the SSL dir as vardir and confdir is ugly, but workable...
puppet cert --trace --generate test01.domain.tld \
    --confdir=/tmp/puppet-ssl-$$ --vardir=/tmp/puppet-ssl-$$ \
    --ssldir=/tmp/puppet-ssl-$$ --debug --verbose

ls /tmp/puppet-ssl-$$/certs/*
