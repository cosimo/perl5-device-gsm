#!/bin/sh
#
# $Id: makedoc.sh,v 1.2 2003-03-24 23:03:45 cosimo Exp $
#

#mv README README.old
#pod2text Gsm.pm >README

mv Gsm.html Gsm.html.old
pod2html Gsm.pm >Gsm.html

perl -i.bak -pe 's/dev\.xproject\.org/cpan.org/g' Gsm.html

