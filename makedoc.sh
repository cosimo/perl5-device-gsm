#!/bin/sh
#
# $Id: makedoc.sh,v 1.1 2002-09-11 22:24:20 cosimo Exp $
#

mv README README.old
pod2text Gsm.pm >README

mv Gsm.html Gsm.html.old
pod2html Gsm.pm >Gsm.html

perl -i.bak -pe 's/dev\.xproject\.org/cpan.org/g' Gsm.html

