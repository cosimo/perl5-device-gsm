#!/bin/sh
#
# $Id: makedoc.sh,v 1.3 2003-03-24 23:06:09 cosimo Exp $
#

#mv README README.old
#pod2text Gsm.pm >README

mv docs/Gsm.html docs/Gsm.html.old
pod2html Gsm.pm >docs/Gsm.html

perl -i.bak -pe 's/dev\.xproject\.org/cpan.org/g' docs/Gsm.html

