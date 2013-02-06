#!/usr/bin/env perl
# Copyright (c) 2005-2010, Vonage Holdings Corp.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY VONAGE HOLDINGS CORP. ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL VONAGE HOLDINGS CORP. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# $Id$
#

#
# this script validates input for an addition, and in the event of problem,
# will send an error message and present the user with an opportunity to
# fix.
#

use strict;
use warnings;
use JazzHands::STAB;
use FileHandle;
use Data::Dumper;
use URI;
use CGI;
use POSIX;

do_dns_update();

#
# I probably need to find a better way to do this.  This allows error
# responses to be much less sucky, but it's going to be way slow.
#
sub clear_same_dns_params {
	my ( $stab, $domid ) = @_;
	my $cgi = $stab->cgi || die "Could not create cgi";
	my $dbh = $stab->dbh || die "Could not create dbh";

	my $q = qq{
		select	d.dns_record_id,
				d.dns_name, d.dns_class, d.dns_type, 
				d.dns_value, d.dns_ttl, d.is_enabled,
				ip_manip.v4_octet_from_int(nb.ip_address) as ip
		  from	dns_record d
				left join netblock nb
					on nb.netblock_id = d.netblock_id
		 where	dns_domain_id = :1
	};
	my $sth = $dbh->prepare($q) || $stab->return_db_err;
	$sth->execute($domid) || $stab->return_db_err;

	my $all = $sth->fetchall_hashref('DNS_RECORD_ID')
	  || $stab->error_return(
		"Unable to obtain existing DNS records from database.");

	my ($purge);

	#
	# iterate over TTL because that's a record that exists for everything,
	# even the uneditable "device" recors.
	#
	# a "next" in this loop causes it to not be removed and is left for
	# consideration later in the script.
	#
	# ttlonly no longer means ttlonly as it now includes is_enabled...
	#
      DNS: for my $dnsid ( $stab->cgi_get_ids('DNS_RECORD_ID') ) {
		next if ( $dnsid !~ /^\d+$/ );

		my $in_name    = $stab->cgi_parse_param( 'DNS_NAME',  $dnsid );
		my $in_class   = $stab->cgi_parse_param( 'DNS_CLASS', $dnsid );
		my $in_type    = $stab->cgi_parse_param( 'DNS_TYPE',  $dnsid );
		my $in_ttl     = $cgi->param( 'DNS_TTL_' . $dnsid );
		my $in_value   = $stab->cgi_parse_param( 'DNS_VALUE', $dnsid );
		my $in_ttlonly = $stab->cgi_parse_param( 'ttlonly',   $dnsid );
		my $in_enabled =
		  $stab->cgi_parse_param( 'chk_IS_ENABLED', $dnsid );

		$in_enabled = $stab->mk_chk_yn($in_enabled);

		if ( !exists( $all->{$dnsid} ) ) {
			next;
		}

		if ( !defined($in_ttl) ) {
			$in_ttl = $all->{$dnsid}->{DNS_TTL};
		}

		if ($in_ttlonly) {
			if ( $all->{$dnsid}->{DNS_TTL} && $in_ttl ) {
				if ( $all->{$dnsid}->{DNS_TTL} != $in_ttl ) {
					next;
				}
			} elsif ( !$all->{$dnsid}->{DNS_TTL} && !$in_ttl ) {
				;
			} else {
				next;
			}

			if ( $all->{$dnsid}->{IS_ENABLED} ne $in_enabled ) {
				next;
			}

		} else {
			if ( $all->{$dnsid}->{DNS_TYPE} eq 'A' ) {
				$all->{$dnsid}->{DNS_VALUE} =
				  $all->{$dnsid}->{IP};
			}

			my $map = {
				DNS_NAME   => $in_name,
				DNS_CLASS  => $in_class,
				DNS_TYPE   => $in_type,
				DNS_VALUE  => $in_value,
				DNS_TTL    => $in_ttl,
				IS_ENABLED => $in_enabled,
			};

	    # if it correponds to an actual row, compare, otherwise only keep if
	    # something is set.
			if (       defined($dnsid)
				&& exists( $all->{$dnsid} )
				&& defined( $all->{$dnsid} ) )
			{
				my $x = $all->{$dnsid};
				foreach my $key ( sort keys(%$map) ) {
					if (       defined( $x->{$key} )
						&& defined( $map->{$key} ) )
					{
						if ( $x->{$key} ne
							$map->{$key} )
						{
							next DNS;
						}
					} elsif (  !defined( $x->{$key} )
						&& !defined( $map->{$key} ) )
					{
						;
					} else {
						next DNS;
					}
				}
			}
		}

		$purge->{ 'DNS_RECORD_ID_' . $dnsid }  = 1;
		$purge->{ 'DNS_NAME_' . $dnsid }       = 1;
		$purge->{ 'DNS_TTL_' . $dnsid }        = 1;
		$purge->{ 'DNS_TYPE_' . $dnsid }       = 1;
		$purge->{ 'DNS_CLASS_' . $dnsid }      = 1;
		$purge->{ 'DNS_VALUE_' . $dnsid }      = 1;
		$purge->{ 'ttlonly_' . $dnsid }        = 1;
		$purge->{ 'chk_IS_ENABLED_' . $dnsid } = 1;
	}

	undef $all;

	my $n = new CGI($cgi);
	$cgi->delete_all;
	my $v = $n->Vars;
	foreach my $p ( keys %$v ) {
		next if ( defined( $purge->{$p} ) );
		$cgi->param( $p, $v->{$p} );
	}

	undef $v;
	undef $n;
	undef $purge;
}

sub process_dns_add {
	my ( $stab, $domid ) = @_;
	my $cgi = $stab->cgi || die "Could not create cgi";
	my $dbh = $stab->dbh || die "Could not create dbh";

	my $numchanges = 0;

	my $name  = $stab->cgi_parse_param('DNS_NAME');
	my $ttl   = $stab->cgi_parse_param('DNS_TTL');
	my $class = $stab->cgi_parse_param('DNS_CLASS');
	my $type  = $stab->cgi_parse_param('DNS_TYPE');
	my $value = $stab->cgi_parse_param('DNS_VALUE');

	if ( !defined($name) && !$ttl && !$class && !$type && !$value ) {
		return $numchanges;
	}

	if ( defined($name) ) {
		$name =~ s/^\s+//;
		$name =~ s/\s+$//;
	}
	if ( defined($value) ) {
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;
	}

	$class = 'IN' if ( !defined($class) );
	if ( !defined($type) || !length($type) ) {
		$stab->error_return("Must set a record type");
	}
	if ( !defined($value) || !length($value) ) {
		$stab->error_return("Must set a value");
	}
	if ( defined($ttl) && $ttl !~ /^\d+$/ ) {
		$stab->error_return("TTL, if set, must be a number");
	}

	my $cur = $stab->get_dns_record_from_name( $name, $domid );
	if ($cur) {
		if ( $type eq 'CNAME' && $cur->{'DNS_TYPE'} ne 'CNAME' ) {
			$stab->error_return(
"You may not add a CNAME, when records of other types exist."
			);
		}
		if ( $type ne 'CNAME' && $cur->{'DNS_TYPE'} eq 'CNAME' ) {
			$stab->error_return(
"You may not add non-CNAMEs when CNAMEs already exist"
			);
		}
	}

	if ( ( !defined($name) || !length($name) ) && $type eq 'CNAME' ) {
		$stab->error_return(
			"CNAMEs are illegal when combined with an SOA record.");
	}
	$numchanges +=
	  process_and_insert_dns_record( $stab, $domid, $name, $ttl, $class,
		$type, $value );

	$numchanges;
}

sub do_dns_update {
	my $stab = new JazzHands::STAB || die "Could not create STAB";
	my $cgi  = $stab->cgi          || die "Could not create cgi";
	my $dbh  = $stab->dbh          || die "Could not create dbh";

	my $numchanges;

	my $domid = $stab->cgi_parse_param('DNS_DOMAIN_ID');

	if ( !dns_domain_authcheck( $stab, $domid ) ) {
		$stab->error_return(
			"You are not authorized to change this zone.");
	}

	clear_same_dns_params( $stab, $domid );

       # print $cgi->header, $cgi->start_html, $cgi->Dump, $cgi->end_html; exit;

	my $genflip = $stab->cgi_parse_param('AutoGen');

	$numchanges += process_dns_add( $stab, $domid );

	# process deletions
	my $delsth;
	foreach my $delid ( $stab->cgi_get_ids('Del') ) {
		if ( !defined($delsth) ) {
			my $q = qq{
				delete from dns_record
				 where	dns_record_id = :1
			};
			$delsth = $stab->prepare($q)
			  || $stab->return_db_err($dbh);
		}
		$delsth->execute($delid) || $stab->return_db_err($delsth);
		$cgi->delete("Del_$delid");
		$cgi->delete("DNS_RECORD_ID_$delid");
		$numchanges++;
	}

	# process updates
	my $updsth;
	foreach my $updateid ( $stab->cgi_get_ids('DNS_RECORD_ID') ) {
		next if ( !$updateid );

		my $name  = $stab->cgi_parse_param( 'DNS_NAME', $updateid );
		my $ttl   = $cgi->param( 'DNS_TTL_' . $updateid );
		my $class = $stab->cgi_parse_param( 'DNS_CLASS', $updateid );
		my $type  = $stab->cgi_parse_param( 'DNS_TYPE', $updateid );
		my $value = $stab->cgi_parse_param( 'DNS_VALUE', $updateid );
		my $enabled =
		  $stab->cgi_parse_param( 'chk_IS_ENABLED', $updateid );
		my $ttlonly = $stab->cgi_parse_param( 'ttlonly', $updateid );

		$enabled = $stab->mk_chk_yn($enabled);

		if ( !$ttlonly ) {

			# this are just informational records.
			next if ( !$name && !$class && !$type && !$value );
			if ($name) {
				$name =~ s/^\s+//;
				$name =~ s/\s+$//;
			}
			if ( !$value ) {
				my $hint = $name || "";
				$hint = "($hint id#$updateid)";
				$stab->error_return(
"Records may not have empty values ($hint)"
				);
			}
			$value =~ s/^\s+//;
			$value =~ s/\s+$//;
		}

		if ( $ttl && $ttl !~ /^\d+/ ) {
			$stab->error_return("TTLs must be numbers");
		}

	   # [XXX] need to check value and deal with it appropriately (or figure
	   # out where quotes should go in the extraction.
		if ( $name && $name =~ /\s/ ) {
			$stab->error_return(
				"DNS Records may not contain spaces");
		}

		$numchanges += process_and_update_dns_record(
			$stab, $updateid, $name,    $ttl, $class,
			$type, $value,    $ttlonly, $enabled
		);

	}

	if ($numchanges) {
		$dbh->commit;
		my $url = "./?dnsdomainid=" . $domid;
		$stab->msg_return( "Zone Updated", $url, 1 );
	}

	$dbh->rollback;
	$stab->msg_return("Nothing to do");
}

sub process_and_insert_dns_record {
	my ( $stab, $domid, $name, $ttl, $class, $type, $value ) = @_;

	my $dbh = $stab->dbh;

	if ( $type eq 'A' ) {
		if ( $value !~ /^(\d+\.){3}\d+/ ) {
			$stab->error_return("$value is not a valid IP address");
		}
		my $block = $stab->get_netblock_from_ip($value);
		if ( !defined($block) ) {
			$stab->error_return(
				"IP Address $value is not reserved");
		}
		$value = $block->{'NETBLOCK_ID'};
	}
	$stab->add_dns_record( $domid, $name, $ttl, $class, $type, $value );

	return 1;
}

sub process_and_update_dns_record {
	my (
		$stab, $dnsrecid, $name,    $ttl, $class,
		$type, $value,    $ttlonly, $enabled
	) = @_;
	my $dbh = $stab->dbh;

	$enabled = 'Y' if ( !defined($enabled) );

	my $orig = $stab->get_dns_record_from_id($dnsrecid);

	if ( !defined($ttl) ) {
		$ttl = $orig->{'DNS_TTL'};
	} elsif ( !length($ttl) ) {
		$ttl = undef;
	}

	my %newrecord;

	if ($ttlonly) {
		%newrecord = (
			DNS_RECIRD_ID => $dnsrecid,
			DNS_TTL       => $ttl,
			IS_ENABLED    => $enabled,
		);
	} else {
		%newrecord = (
			DNS_RECIRD_ID => $dnsrecid,
			DNS_TTL       => $ttl,
			DNS_NAME      => $name,
			DNS_VALUE     => $value,
			IS_ENABLED    => $enabled,
		);
	}
	if ( defined($class) ) {
		$newrecord{'DNS_CLASS'} = $class;
	}

	if ( defined($type) ) {
		$newrecord{'DNS_TYPE'} = $type;
	}

	if ( $orig->{'DNS_TYPE'} ne 'A' && $type eq 'A' ) {
		$newrecord{'DNS_VALUE'} = undef;

		if ( $value !~ /^(\d+\.){3}\d+/ ) {
			$stab->error_return("$value is not a valid IP address");
		}

		my $block = $stab->get_netblock_from_ip($value);
		if ( !defined($block) ) {
			$stab->error_return("IP Address is not reserved");
		}
		$newrecord{'NETBLOCK_ID'} = $block->{'NETBLOCK_ID'};
	}

	my $diffs = $stab->hash_table_diff( $orig, \%newrecord );
	my $tally = keys %$diffs;
	if ( !$tally ) {
		return 0;
	} elsif (
		!$stab->build_update_sth_from_hash(
			"DNS_RECORD", "DNS_RECORD_ID", $dnsrecid, $diffs
		)
	  )
	{
		$dbh->rollback;
		$stab->error_return(
			"Unknown Error with Update for id#$dnsrecid");
	}
	return $tally;
}

#
# returns 1 if someone is authorized to change a given domain id,
# returns 0 if not.
#
sub dns_domain_authcheck {
	my ( $stab, $domid ) = @_;

	my $cgi = $stab->cgi;

	#
	# if there's no htaccess file, return ok.
	#
	my $htaccess = $cgi->path_translated();
	if ( !$htaccess && $cgi->{'.r'} ) {

		# I'm sure this is illegal.
		$htaccess = $cgi->{'.r'}->filename;
	}
	return 0 if ( !$htaccess );
	$htaccess =~ s,/[^/]+$,/,;
	$htaccess .= "write/.htaccess";
	my $fh = new FileHandle($htaccess);
	return 0 if ( !$fh );
	my $wwwgroup = undef;
	while ( my $line = $fh->getline ) {

		if ( $line =~ /^\s*Require\s+group\s+(\S+)\s*$/ ) {
			$wwwgroup = $1;
			last;
		}
	}
	$fh->close;

	#
	# if there's no require group, then give access
	#
	return 0 if ( !$wwwgroup );

	#
	# if there is a domain, look for ${wwwgroup} or ${wwwgroup}--domain
	#
	my $altwwwgroup = $wwwgroup;
	my $hr          = $stab->get_dns_domain_from_id($domid);
	if ($hr) {
		$altwwwgroup = $wwwgroup . "--" . $hr->{'SOA_NAME'};
	}

	#
	# look through the www group.  This must match the apache config.  Yes,
	# this is a gross hack.
	#
	# if there's no auth directory, then its not on, and return.
	# (this needs to move to db based auth)
	return 1 if(! -d "/prod/www/auth");
	my $fn   = "/prod/www/auth/groups";
	my $auth = new FileHandle($fn);

	#
	# fail if the file isn't there.
	#
	return 0 if ( !$auth );

	my $userlist;
	while ( my $line = $auth->getline ) {
		chomp($line);
		my ( $g, $u ) = split( /:/, $line, 2 );
		next if ( !$g || !$u );
		if ( $g eq $altwwwgroup ) {
			$userlist = $u;
			last;
		} elsif ( $g eq $wwwgroup ) {
			$userlist = $u;
		}
	}
	$auth->close;

	my $dude = $cgi->remote_user;
	return 0 if ( !$dude );
	return 0 if ( !$userlist );

	return 1 if ( $userlist =~ /\b$dude\b/ );
	return 0;
}
