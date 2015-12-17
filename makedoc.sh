#!/bin/sh

#mv README README.old
#pod2text Gsm.pm >README

mv docs/Gsm.html docs/Gsm.html.old
pod2html Gsm.pm >docs/Gsm.html

mv docs/GsmSms.html docs/GsmSms.html.old
pod2html lib/Device/Gsm/Sms.pm >docs/GsmSms.html

perl -i.bak -pe 's/dev\.xproject\.org/cpan.org/g' docs/*.html
