#!/usr/bin/perl -w

# $Id: Modem__Hayes.pl,v 1.1 2003-03-23 08:14:32 cosimo Exp $

use Device::SerialPort qw(:STAT 0.07);
use strict;

$Modem::Hayes::log_pipe = 0;		# log pipe handler
my $mdm_debug = 1;			# controls the amount of logging via the log pipe

#--------------
# subfunctions
#--------------
sub print_dbg($);
sub log_msg($);

# init
sub init_port ($$$$$$);
sub mdm_init;

# output
sub mdm_send_cmd ($$$$);
sub mdm_send_str ($$$);
sub mdm_connect_to ($$$$);
sub mdm_disconnect ($);

# input
sub mdm_wait4data ($$);
sub mdm_wait4str ($$$);
sub mdm_read_pending_input ($$);

#-------------
# definitions
#-------------
sub log_msg($) {
    my $msg = $_[0];
    &$Modem::Hayes::log_pipe ($msg);
}

sub print_dbg($) {
    my $msg = $_[0];
    if ($mdm_debug) {
	&$Modem::Hayes::log_pipe ($msg);
    }
}
#--------------------------------------------------------------------
sub init_port($$$$$$) {
    my ($Port,$bps,$data,$parity,$stop,$LockGracePeriod) = @_[0..5];

    my $Modem;
    my $LockFile = "/var/lock/LCK..$Port";
    my $Device = "/dev/$Port";

    $Modem = Device::SerialPort->new ($Device,"true",$LockFile);
    unless ($Modem) {
	if ($Modem == 0) {
	    &log_msg("init_port: Port <$Port> is locked.") ;
	    sleep $LockGracePeriod;
	    &log_msg("init_port: Waited $LockGracePeriod seconds.");
	    $Modem = Device::SerialPort->new ($Device,"true",$LockFile);
	    unless ($Modem) {
		if ($Modem == 0) {
		    &log_msg("init_port: Port <$Port> is still locked.") ;
		} else {
		    &log_msg("init_port: Still unable to open port <$Port> for reasons other than locking.");
		}
	    }
	} else {
	    &log_msg("init_port: Unable to open port <$Port> for reasons other than locking.");
	    &log_msg("init_port: Don't know what to do. Giving up.");
	}
	undef $Modem;
	return undef;
    }

    &log_msg("Port <$Port> not locked. OK to use.");

    # set port parameters:
    #  user messages
    unless ($Modem->user_msg(1)) {
	&log_msg("init_port: Cannot activate user messages on device <$Device>.");
	undef $Modem;
	return undef;
    }
    #  decoding of error bitmasks
    unless ($Modem->error_msg(1)) {
	&log_msg("init_port: Cannot activate bitmap error decoding on device <$Device>.");
	undef $Modem;
	return undef;
    }
    #  baudrate
    unless ($Modem->baudrate($bps)) {
	&log_msg("init_port: Cannot set port speed to \"$bps\" on device <$Device>.");
	&log_msg("init_port: Valid speeds: " . join(', ', $Modem->baudrate));
	undef $Modem;
	return undef;
    }
    #  data bits
    unless ($Modem->databits($data)) {
	&log_msg("init_port: Cannot set data bits to \"$data\" on device <$Device>.");
	&log_msg("init_port: Valid data bit numbers: " . join(', ', $Modem->databits));
	undef $Modem;
	return undef;
    }
    #  parity
    unless ($Modem->parity($parity)) {
	&log_msg("init_port: Cannot set parity to \"$parity\" on device <$Device>.");
	&log_msg("init_port: Valid parities: " . join(', ', $Modem->parity));
	undef $Modem;
	return undef;
    }
    #  really enable parity processing
    unless ($parity eq "none") {
	unless (defined $Modem->parity_enable("true")) {
	    &log_msg("init_port: Cannot enable parity processing on device <$Device>.");
	    undef $Modem;
	    return undef;
	}
    }
    #  stop bits
    unless ($Modem->stopbits($stop)) {
	&log_msg("init_port: Cannot set stop bits to \"$stop\" on device <$Device>.");
	&log_msg("init_port: Valid stop bit numbers: " . join(', ', $Modem->stopbits));
	undef $Modem;
	return undef;
    }
    #  handshake hardcoded to CTS/RTS
    unless ($Modem->handshake("rts")) {
	&log_msg("init_port: Cannot set handshake to \"RTS/CTS\" on device <$Device>.");
	undef $Modem;
	return undef;
    }
    # commit settings to hardware
    unless ($Modem->write_settings) {
	&log_msg("init_port: Cannot commit settings to port hardware on device <$Device>.");
	undef $Modem;
	return undef;
    }
    print_dbg("init_port: successful");
    return $Modem;
}
#--------------------------------------------------------------------
# this tries to make sure the modem is operational and compatible,
# it also tries to initialise it
sub mdm_init {
    my $Modem = shift @_;
    my @InitCodes = @_;
    my $try;
    my $tmp;

    # raise DTR
    $Modem->dtr_active("1");

    # purge buffers
    $Modem->lookclear;
    $Modem->purge_all;

    # try to activate (x3) = compatibility check
    $try = 0;
    $tmp = 0;
    do {
	$try++;
	$tmp = mdm_send_cmd($Modem,"at","OK\r\n",6000);
    } until (($tmp == 1) or ($try = 3));

    unless ($tmp == 1) {
	&log_msg("mdm_init: Modem does not answer \"OK\" after 3 tries of sending \"AT\".");
	&log_msg("mdm_init: Perhaps it is not AT compatible ?");
	&log_msg("mdm_init: Make sure it's connected correctly and try switching it off and back on.");
	return undef;
    }
    print_dbg("mdm_init: received OK after AT<cr><lf>");
    # - read out S3/S4 -> codes for CR/LF -> CmdSuffix

    # - send init codes
    foreach $tmp (@InitCodes) {
	unless (mdm_send_cmd($Modem,$tmp,"OK\r\n",3000)) {
	    &log_msg("mdm_init: Modem does not answer \"OK\" after init command \"$tmp\".");
	    &log_msg("mdm_init: Make sure it's connected correctly and try switching it off and back on.");
	    return undef;
	}
	print_dbg("mdm_init: sent init code \"$tmp\"");
    }

    # test if DSR is high (= modem ready) - configurable !!
    $tmp = $Modem->modemlines;
    if (! ($tmp & $Modem->MS_DSR_ON)) {
	&log_msg("mdm_init: DSR is not high ! Modem signals: $tmp");
	&log_msg("mdm_init: Hoping for the best.");
    }

    # - read out S7 -> connect wait time if aCfg.ConnectWait = 0
    # - read out S2 -> ESC code
    # - read out S12 -> ESC guard time

    # purge buffers again
    $Modem->lookclear;
    $Modem->purge_all;

    print_dbg("mdm_init: successful");
    return 1;
}
#--------------------------------------------------------------------
# send a string with some timeout
sub mdm_send_str ($$$) {
    my ($aModem,$aStr,$aTimeout) = @_;

    my $tmp;
    my $slice = 50;
    my $try = 0;
    my $MaxTries;

    print_dbg ("mdm_send_str: string: \"$aStr\"");

    # now send the string
    $tmp = $aModem->write($aStr);

    # failed to send anything
    unless ($tmp) {
	&log_msg("mdm_send_str: Cannot send \"$aStr\" to modem at all.");
	return 0;
    };
    print_dbg("mdm_send_str: something was sent at least");

    # failed to send entire string
    if ($tmp != length($aStr)) {
	&log_msg("mdm_send_str: Failed to send entire string (\"$aStr\") to modem.");
	&log_msg("mdm_send_str: # of chars sent: \"$tmp\"");
	return 0;
    }
    print_dbg("mdm_send_str: the whole string was sent");

    # calculate # of time slices to wait for end of transmission
    $MaxTries = (($aTimeout - ($aTimeout % $slice)) / $slice);

    # be sane, though
    if ($MaxTries == 0) {$MaxTries = 1}

    print_dbg("mdm_send_str: waiting at most $MaxTries slices á $slice ms for end of hardware transmission");

    # wait until hardware finished transmitting
    while ((! $aModem->write_drain) and ($try < $MaxTries)) {
	$try++;
	select(undef,undef,undef,($slice/1000));
    }
    
    # success ?
    if ($aModem->write_drain) {
	print_dbg ("mdm_send_str: successful");
	return 1;
    } else {
	&log_msg("Timeout (> $aTimeout ms) occurred in port hardware while sending \"$aStr\"");
	return 0;
    }
}
#--------------------------------------------------------------------
# this sends an AT command to the modem and evaluates the response
sub mdm_send_cmd ($$$$) {
    my ($aModem,$aCmd,$anExpectedAnswer,$aDelay) = @_;
    my $tmp;
    my $rxd;

    # sanity check cmd for suffix
    if ($aCmd !~ /\r\n$/) {
	$aCmd = $aCmd . "\r\n"
    }

    print_dbg("mdm_send_cmd: cmd: \"$aCmd\"");

    # empty buffers so we don't get fooled by old data
    $aModem->lookclear;
    $aModem->purge_all;

    # now send the string
    $tmp = mdm_send_str($aModem,$aCmd,2000);
    unless ($tmp) {
	&log_msg("mdm_send_cmd: Cannot send \"$aCmd\" to modem.");
	return 0;
    }

    print_dbg ("mdm_send_cmd: cmd sent");

    # and wait until we got what we want or got a timeout
    ($tmp,$rxd) = mdm_wait4str ($aModem,$anExpectedAnswer,$aDelay) ;

    print_dbg ("mdm_send_cmd: answer: \"$rxd\"");

    # unsuccessful
    if ($tmp == 0) {
	&log_msg("mdm_send_cmd: Did not receive \"$anExpectedAnswer\" after \"$aCmd\" even with a timeout of $aDelay ms.");
	&log_msg("mdm_send_cmd: Received instead: \"$rxd\"");
	return 0;
    }
    # successful
    if ($tmp == 1) {
	print_dbg ("mdm_send_cmd: successful");
	return 1;
    # should not happen
    } else {
	print_dbg ("mdm_send_cmd: this should not occur (tmp=$tmp)");
	return 0;
    }
}
#--------------------------------------------------------------------
# wait for a (one) given string to arrive
sub mdm_wait4str($$$) {
    my $modem = shift @_;
    my $expected = shift @_;
    my $timeout = shift @_;
    my $rxd = "";
    my $try = 0;
    my $MaxTries;
    my $slice = 20;	# ms
    my $char = "";
    my $bytes_read = 0;
    my $found_at = -1;

    # calculate number of tries for polling
    $MaxTries = (($timeout - ($timeout % $slice)) / $slice);

    # be sane, though
    if ($MaxTries < 4) {$MaxTries = 4}

    # as long as we have any time left (= slices to try in) look for data
    # we will set $try to $MaxTries if we find what we want
    while ($try < $MaxTries) {
	# any data there already ?
	($bytes_read,$char) = $modem->read(1);
	# nope, so:
	while (($bytes_read == 0) and ($try < $MaxTries)) {
	    # wait
	    select (undef,undef,undef,($slice/1000));
	    # and check if there's anything there now,
	    ($bytes_read,$char) = $modem->read(1);
	    # but only for so many times
	    $try++;
	}
	# sanity check
	if ($bytes_read > 1) {
	    print_dbg ("We received more than one byte although we requested only one.");
	    print_dbg ("Let's hope for the best.");
	}
	# did we receive anything ?
	if ($bytes_read == 1) {
	    # yes - so save the char
	    $rxd = $rxd . $char;
	    # check if what we received so far includes what we are waiting for
	    $found_at = index $rxd, $expected;
	    # got it ?
	    if ($found_at >= 0) {
		# yep - so return what we got
		print_dbg("mdm_wait4str: just received \"$expected\"");
		return (1,$rxd);
	    } else {
		# nope - do we have slices left ?
		if ($try >= $MaxTries) {
		    # no - so return what we received so far
		    return (0,$rxd);
		}
		    # yes - so wait on
	    }
	} else {
	    # no - must be a timeout
	    # so return the string that we received so far
	    return (0,$rxd);
	}
    }
    print_dbg("mdm_wait4str: we should never get here.");
}
#--------------------------------------------------------------------
sub mdm_connect_to ($$$$) {
    my $modem = shift @_;
    my $dialcmd = shift @_;
    my $number = shift @_;
    my $MaxTries = shift @_;

    my $dialstr;
    my $try = 0;
    my $tmp;
    my $rxd;
    my $timeout;

    # construct complete dial str
    $dialstr = $dialcmd . $number .. "\r\n";
    print_dbg("mdm_connect_to: dial string = \"$dialstr\"");

    # try to connect
    while ($try < $MaxTries) {
	$try++;
	print_dbg("mdm_connect_to: connect try #" . $try);

	# purge buffers
	$modem->lookclear;
	$modem->purge_all;

	# send dial string
	$tmp = mdm_send_str($modem,$dialstr,3000);
	unless ($tmp) {
	    &log_msg("mdm_connect_to: Cannot send \"$dialstr\" to modem.");
	    return 0;
	}

	# wait for connect
	# - this should be much more refined !
	# - it should not only check for CONNECT
	# - the delay should not be hardcoded
	($tmp,$rxd) = mdm_wait4str ($modem,"CONNECT",45000) ;

	# not connected
	if ($tmp == 0) {
	    &log_msg("mdm_connect_to: Did not receive \"CONNECT\" after \"$dialstr\" even with a timeout of 45 s.");
	    &log_msg("mdm_connect_to: Received instead: \"$rxd\"");
	    &log_msg("mdm_connect_to: Trailing junk:");
	    ($tmp,$rxd) = mdm_read_pending_input ($modem,5000) ;
	    &log_msg($rxd);
	    return 0;
	}
	# connected
	if ($tmp == 1) {
	    ($tmp,$rxd) = mdm_read_pending_input ($modem,500) ;
	    print_dbg("mdm_connect_to: was pending: " . $rxd);
	    print_dbg("mdm_connect_to: connected");
	    return 1;
	}
    }
    # not connected but can't retry because tries exhausted
    ($tmp,$rxd) = mdm_read_pending_input ($modem,5000) ;
    &log_msg($rxd);
    &log_msg("mdm_connect_to: not connected but out of tries");
    return 0;
}
#--------------------------------------------------------------------
sub mdm_disconnect($) {
    my $modem = shift @_;
    my $tmp;
    my $rxd;

    # wait for NO CARRIER
    ($tmp,$rxd) = mdm_wait4str ($modem,"NO CARRIER",5000);

    # not received ?
    if ($tmp == 0) {
	&log_msg("Remote modem did not hangup (send \"NO CARRIER\") within 2 seconds.");
	&log_msg("Received instead: \"$rxd\"");

	# wait Guard Time seconds (S 12)
	sleep 2;

	# send DLE code (S 2) three times, not more than Guard Time seconds apart
	# and wait Guard Time seconds (S 12)
	$tmp = mdm_send_str($modem,"+++",1000);
	unless ($tmp) {
	    &log_msg("mdm_disconnect: Cannot send \"+++\" to modem.");
	}

	# and wait until we got what we want or got a timeout
	($tmp,$rxd) = mdm_wait4str ($modem,"OK",2000) ;
	print_dbg ("mdm_disconnect: answer: \"$rxd\"");

	# unsuccessful
	if ($tmp == 0) {
	    &log_msg("mdm_disconnect: Did not receive \"OK\" after \"+++\" even with a timeout of 2000 ms.");
	    &log_msg("mdm_disconnect: Received instead: \"$rxd\"");
	}

	# send hangup command
	$tmp = mdm_send_cmd($modem,"ath0","OK",2000);
	unless ($tmp) {
	    &log_msg("Cannot send \"ath0\" to modem.");
	}
    }

    # drop DTR for 100 msecs
    $modem->pulse_dtr_off(100);
    
    # check for CD to be low
    $tmp = $modem->modemlines;
    if ($tmp & $modem->MS_RLSD_ON) {
	&log_msg("CD isn't low after dropping DTR ! Modem signals: $tmp");
    }

    # reinit modem
    mdm_init($modem, @_);
    
    # purge buffers
    $modem->lookclear;
    $modem->purge_all;

    return 1;
}
#--------------------------------------------------------------------
# wait for some data (any) to arrive
sub mdm_wait4data($$) {
    my $modem = shift @_;
    my $timeout = shift @_;	# ms !

    my $rxd = "";
    my $tmp = "";
    my $slice = 20;		# ms
    my $time_used = 0;    
    my $bytes_read;

    # any data there already ?
    ($bytes_read,$rxd) = $modem->read(1);
    # nope, so loop:
    while (($bytes_read == 0) and ($time_used < $timeout)) {
	# wait
	select (undef,undef,undef,($slice/1000));
	# and check if there's anything there now,
	($bytes_read,$tmp) = $modem->read(1);
	$rxd = $rxd . $tmp;
	# but only for so many times
	$time_used = ($time_used + $slice);
    }
    # sanity check
    if ($bytes_read > 1) {
	print_dbg("mdm_wait4data: We received more than one byte although we requested only one.");
	print_dbg("mdm_wait4data: Let's hope for the best.");
    }
    # did we receive anything ?
    if ($bytes_read == 0) {
	# nope
	&log_msg("mdm_wait4data: No data received on modem even after $timeout ms.");
	return(0,"");
    } else {
	# yep
	print_dbg("mdm_wait4data: received something: \"$rxd\"");
	return (1,$rxd);
    }
}
#--------------------------------------------------------------------
sub mdm_read_pending_input ($$) {
    my $modem = shift @_;
    my $timeout = shift @_;	# ms

    my $slice = 20;		# ms
    my $time_used = 0;
    my $rxd = "";
    my $tmp = "";
    my $tmp1 = "";

    ($tmp,$rxd) = mdm_wait4data ($modem,$timeout);
    if ($tmp) {
	while ($time_used < $timeout) {
	    $time_used = $time_used + $slice;
	    ($tmp,$tmp1) = mdm_wait4data ($modem,$slice);
	    $rxd = $rxd . $tmp1;
	}
    }

    # purge input buffer
    #$modem->purge_rx;

    if ($rxd eq "") {
	print_dbg("mdm_read_pending_input: no pending input found");
	return (0,"");
    } else {
	print_dbg("mdm_read_pending_input: pending input was:  \"$rxd\"");
	return (1,$rxd);
    }
}
#--------------------------------------------------------------------
# $Log: not supported by cvs2svn $
# Revision 1.8  2001/02/03 13:37:09  root
# - cleaned up message logging by using a pipe into the main log
# - really do 3 tries of sending AT now before declaring the modem incompatible
#
# Revision 1.7  2001/01/07 20:08:24  root
# - fixed a type (<cr> vs. <lf>)
# - fixed a bug in date handling (localtime gives month starting at 0)
#
# Revision 1.6  2001/01/07 12:01:38  root
# - first version to be tested on Horus (6.1.2001)
#
# Revision 1.5  2001/01/02 23:42:34  root
# - first version that worked at least once (Bautzen Kinder)
#
# Revision 1.4  2000/12/25 21:27:31  root
# - heavy logging added, controlled by $mdm_debug
#
# Revision 1.3  2000/10/16 16:59:33  root
# - mdm_connect_to and mdm_disconnect should work now, too
#
# Revision 1.2  2000/10/15 11:28:34  root
# - port and modem init work now
# - mdm_send_cmd and mdm_wait4str work as expected
#
# Revision 1.1  2000/10/07 15:42:54  root
# Initial revision
#
#-------------------------------------------------------
# leave this here, perl wants it !
1;
