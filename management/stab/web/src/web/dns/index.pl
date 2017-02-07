#!/usr/bin/env perl

#
# Copyright (c) 2016-2017 Todd Kover
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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

use strict;
use warnings;
use POSIX;
use Data::Dumper;
use Carp;
use JazzHands::STAB;
use JazzHands::Common qw(_dbx);
use Net::IP;

do_dns_toplevel();

sub do_dns_toplevel {
	my $stab = new JazzHands::STAB || die "Could not create STAB";
	my $cgi  = $stab->cgi          || die "Could not create cgi";

	my $dnsid    = $stab->cgi_parse_param('dnsdomainid');
	my $dnsrecid = $stab->cgi_parse_param('DNS_RECORD_ID');

	if ($dnsrecid) {
		dump_zone( $stab, $dnsid, $dnsrecid );
	} elsif ( !defined($dnsid) ) {
		dump_all_zones_dropdown($stab);
	} else {
		dump_zone( $stab, $dnsid );
	}
	undef $stab;
}

sub dump_all_zones_dropdown {
	my ($stab) = @_;
	my $cgi = $stab->cgi || die "Could not create cgi";

	print $cgi->header( { -type => 'text/html' } ), "\n";
	print $stab->start_html( { -title => "DNS Zones", -javascript => 'dns' } ),
	  "\n";

	print $cgi->h4( { -align => 'center' }, "Find a Zone" );
	print $cgi->start_form( { -action => "search.pl" } );
	print $cgi->start_table( { -align => 'center' } );
	print $stab->build_tr( undef, undef, "b_dropdown", "Zone",
		'DNS_DOMAIN_ID' );
	print $cgi->Tr( { -align => 'center' },
		$cgi->td(
			{ -colspan => 2 },
			$cgi->submit(
				-name  => "Zone",
				-value => "Go to Zone"
			)
		)
	);
	print $cgi->end_table;
	print $cgi->end_form;

	print $cgi->hr;

	print $cgi->h4( { -align => 'center' },
		$cgi->a( { -href => "addazone.pl" }, "Add A Zone" ) );

	print $cgi->hr;

	print $cgi->h4( { -align => 'center' },
		"Reconcile non-autogenerated zones" );
	print $cgi->start_form(
		{ -action => "dns-reconcile.pl", -method => 'GET' } );
	print $cgi->start_table( { -align => 'center' } );
	print $stab->build_tr( { -only_nonauto => 'yes' },
		undef, "b_dropdown", "Zone", 'DNS_DOMAIN_ID' );
	print $cgi->Tr(
		{ -align => 'center' },
		$cgi->td(
			{ -colspan => 2 },
			$cgi->submit(
				-name  => "Zone",
				-value => "Go to Zone"
			)
		)
	);
	print $cgi->end_table;
	print $cgi->end_form;

	print $cgi->end_html, "\n";
}

sub dump_all_zones {
	my ( $stab, $cgi ) = @_;

	print $cgi->header( { -type => 'text/html' } ), "\n";
	print $stab->start_html( { -title => "DNS Zones", -javascript => 'dns' } ),
	  "\
n";

	my $q = qq{
		select 	dns_domain_id,
			soa_name,
			soa_class,
			soa_ttl,
			soa_serial,
			soa_refresh,
			soa_retry,
			soa_expire,
			soa_minimum,
			soa_mname,
			soa_rname,
			should_generate,
			last_generated
		  from	dns_domain
		order by soa_name
	};
	my $sth = $stab->prepare($q) || return $stab->return_db_err;
	$sth->execute || return $stab->return_db_err($sth);

	my $maxperrow = 4;

	print $cgi->start_table( { -border => 1, -align => 'center' } ), "\n";

	my $curperrow = -1;
	my $rowtxt    = "";
	while ( my $hr = $sth->fetchrow_hashref ) {
		if ( ++$curperrow == $maxperrow ) {
			$curperrow = 0;
			print $cgi->Tr($rowtxt), "\n";
			$rowtxt = "";
		}

		if ( !defined( $hr->{ _dbx('LAST_GENERATED') } ) ) {
			$hr->{ _dbx('LAST_GENERATED') } =
			  $cgi->escapeHTML('<never>');
		}

		my $xbox =
		  $stab->build_checkbox( $hr, "ShouldGen", "SHOULD_GENERATE",
			'DNS_DOMAIN_ID' );

		my $serial  = $stab->b_textfield( $hr, 'SOA_SERIAL',  'DNS_DOMAIN_ID' );
		my $refresh = $stab->b_textfield( $hr, 'SOA_REFRESH', 'DNS_DOMAIN_ID' );
		my $retry   = $stab->b_textfield( $hr, 'SOA_RETRY',   'DNS_DOMAIN_ID' );
		my $expire  = $stab->b_textfield( $hr, 'SOA_EXPIRE',  'DNS_DOMAIN_ID' );
		my $minimum = $stab->b_textfield( $hr, 'SOA_MINIMUM', 'DNS_DOMAIN_ID' );

		my $link =
		  build_dns_link( $stab, $hr->{ _dbx('DNS_DOMAIN_ID') } );
		my $zone =
		  $cgi->a( { -href => $link }, $hr->{ _dbx('SOA_NAME') } );

		my $entry = $cgi->table(
			{ -width => '100%', -align => 'top' },
			$cgi->Tr(
				$cgi->td(
					{
						-align => 'center',
						-style => 'background: green'
					},
					$cgi->b($zone)
				)
			),

			#$cgi->Tr($cgi->td("Serial: ", $serial )),
			#$cgi->Tr($cgi->td("Refresh: ", $refresh )),
			#$cgi->Tr($cgi->td("Retry: ", $retry )),
			#$cgi->Tr($cgi->td("Expire: ", $expire )),
			#$cgi->Tr($cgi->td("Minimum: ", $minimum )),
			$cgi->Tr( $cgi->td( "LastGen:", $hr->{ _dbx('LAST_GENERATED') } ) ),
			$cgi->Tr( $cgi->td($xbox) )
		) . "\n";

		$rowtxt .= $cgi->td( { -valign => 'top' }, $entry );
	}
	print $cgi->Tr($rowtxt), "\n";
	print $cgi->end_table;
	print $cgi->end_html, "\n";

	$sth->finish;
}

sub build_dns_zone {
	my ( $stab, $dnsdomainid, $dnsrecid ) = @_;

	my $cgi = $stab->cgi || die "Could not create cgi";

	my @limit;
	push( @limit, "dns_domain_id = :dns_domain_id" );

	if ($dnsrecid) {
		push( @limit, "dns_record_id = :dns_record_id" );
	}

	my $sth = $stab->prepare(
		qq{
		SELECT  d.*, device_id
		FROM	v_dns_sorted d
				LEFT JOIN network_interface USING (netblock_id)
		} . "WHERE " . join( "\nAND ", @limit )
	) || return $stab->return_db_err;

	$sth->bind_param( ':dns_domain_id', $dnsdomainid );
	if ($dnsrecid) {
		$sth->bind_param( ':dns_record_id', $dnsrecid );
	}

	$sth->execute() || return $stab->return_db_err($sth);

	my $count = 0;
	while ( my $hr = $sth->fetchrow_hashref ) {
		print build_dns_rec_Tr( $stab, $hr, ($count++%2)?'even':'odd' );
	}
	$sth->finish;
}

#
# build the row for a (possibly) editable dns record.
#
# Some things end up not being editable but just become links to other
# records.
#
sub build_dns_rec_Tr {
	my ( $stab, $hr, $basecssclass ) = @_;

	my $cssclass = 'dnsupdate';

	my $cgi = $stab->cgi || die "Could not create cgi";

	my $opts = {};

	if ( !defined($hr) ) {
		$opts->{-prefix} = "new_";
		$opts->{-suffix} = "_0";
	}

	$opts->{-class} = 'dnsttl';
	my $ttl =
	  $stab->b_offalwaystextfield( $opts, $hr, 'DNS_TTL', 'DNS_RECORD_ID' );
	delete $opts->{-class};

	my $value = "";
	my $name  = "";
	my $class = "";
	my $type  = "";

	my $dnsrecid;

	if ( defined($hr) && defined( $hr->{ _dbx('DNS_NAME') } ) ) {
		$name = $hr->{ _dbx('DNS_NAME') };
	}

	if ( defined($hr) && $hr->{ _dbx('DNS_TYPE') } =~ /^A(AAA)?$/ ) {
		$dnsrecid = $hr->{ _dbx('DNS_RECORD_ID') };
	}

	my $showexcess = 1;
	my $ttlonly    = 0;

	my $canedit = 1;

	if ( !$hr->{ _dbx('DNS_RECORD_ID') } ) {
		$name     = $hr->{ _dbx('DNS_NAME') };
		$class    = $hr->{ _dbx('DNS_CLASS') };
		$type     = $hr->{ _dbx('DNS_TYPE') };
		$value    = $hr->{ _dbx('DNS_VALUE') };
		$ttl      = "";
		$canedit  = 0;
		$cssclass = 'dnsinfo';
	} else {
		if ( $hr->{ _dbx('REF_RECORD_ID') } ) {
			$name = $hr->{ _dbx('DNS_NAME') };
		} else {
			$opts->{-class} = 'dnsname';
			$name =
			  $stab->b_textfield( $opts, $hr, 'DNS_NAME', 'DNS_RECORD_ID' );
			delete $opts->{-class};
		}
		$class =
		  $stab->b_dropdown( $opts, $hr, 'DNS_CLASS', 'DNS_RECORD_ID', 1 );

		$opts->{-class} = 'dnstype';
		$type = $stab->b_dropdown( $opts, $hr, 'DNS_TYPE', 'DNS_RECORD_ID', 1 );
		delete( $opts->{-class} );

		if ( defined($hr) && $hr->{ _dbx('DNS_TYPE') } =~ /^A(AAA)?$/ ) {

			# [XXX] hack hack hack, needs to be fixed right so it doesn't
			# show up as a value, but the network.  I think.
			$hr->{ _dbx('DNS_VALUE') } = $hr->{ _dbx('IP') };
		}
	}

	if ( $hr->{ _dbx('DNS_VALUE_RECORD_ID') } ) {
		if ( !$hr->{ _dbx('NETBLOCK_ID') } ) {
			my $link =
			  "./?DNS_RECORD_ID=" . $hr->{ _dbx('DNS_VALUE_RECORD_ID') };
			$value = $cgi->a( { -href => $link }, $hr->{ _dbx('DNS_VALUE') } );
		} else {
			my $link =
			  "./?DNS_RECORD_ID=" . $hr->{ _dbx('DNS_VALUE_RECORD_ID') };
			$value = $cgi->a( { -href => $link }, $hr->{ _dbx('IP') } );
		}
	} else {
		$opts->{-class} = 'dnsvalue';
		$value = $stab->b_textfield( $opts, $hr, 'DNS_VALUE', 'DNS_RECORD_ID' );
		if ($dnsrecid) {
			$value .= $cgi->a(
				{ -class => 'dnsref', -href => 'javascript:void(null)' },
				$cgi->img(
					{
						-src   => "../stabcons/arrow.png",
						-alt   => "DNS Records Referencing This Name",
						-title => 'DNS Records Referencing This Name',
						-class => 'devdnsref',
					}
				),
				$cgi->hidden(
					{
						-class    => 'dnsrecordid',
						-name     => '',
						-value    => $dnsrecid,
						-disabled => 1
					}
				),
			);
		}
		delete( $opts->{-class} );
	}

	if ( $hr->{ _dbx('DEVICE_ID') } ) {
		if ( $hr->{ _dbx('DNS_TYPE') } eq 'PTR' ) {
			my $link =
			  "../device/device.pl?devid=" . $hr->{ _dbx('DEVICE_ID') };
			$value = $cgi->a( { -href => $link }, $value );
		} elsif ( $hr->{ _dbx('DNS_TYPE') } =~ /^A(AAA)?$/ ) {
			$ttlonly = 1;
			my $link =
			  "../device/device.pl?devid=" . $hr->{ _dbx('DEVICE_ID') };
			$name = $cgi->a( { -href => $link }, $name );
		}
	}

	my $args      = { '-class' => "dnsrecord $basecssclass $cssclass" };
	my $enablebox = "";
	my $ptrbox    = "";
	my $hidden    = "";
	my $excess    = "";

	if ($canedit) {
		$opts->{-default} = 'Y';
		if ($showexcess) {
			if ( defined($hr) && $hr->{ _dbx('DNS_RECORD_ID') } ) {
				$excess .= $cgi->checkbox(
					{
						-name  => "Del_" . $hr->{ _dbx('DNS_RECORD_ID') },
						-label => 'Delete',
					}
				);
			} else {
				$cssclass = "dnsadd";
				$excess .= "(Add)";
			}
		}
		if ( $ttlonly && defined($hr) ) {
			$excess .= $cgi->hidden(
				{
					-name  => "ttlonly_" . $hr->{ _dbx('DNS_RECORD_ID') },
					-value => 'ttlonly'
				}
			);
		}

		if ( $hr && $hr->{ _dbx('DNS_RECORD_ID') } ) {
			$hidden = $cgi->hidden(
				{
					-name  => "DNS_RECORD_ID_" . $hr->{ _dbx('DNS_RECORD_ID') },
					-value => $hr->{ _dbx('DNS_RECORD_ID') }
				}
			);
		}

		$enablebox =
		  $stab->build_checkbox( $opts, $hr, "", "IS_ENABLED",
			'DNS_RECORD_ID' );
		delete( $opts->{-default} );

		$ptrbox = "";
		if ( $hr && !$hr->{ _dbx('DNS_VALUE_RECORD_ID') } && $hr->{ _dbx('DNS_TYPE') } =~ /^A(AAA)?$/ ) {
			$opts->{-class} = "ptrbox";
			$ptrbox =
			  $stab->build_checkbox( $opts,
				$hr, "", "SHOULD_GENERATE_PTR", 'DNS_RECORD_ID' );
			delete( $opts->{-class} );
		}

		# for SRV records, it iss necessary to prepend the
		# protocol and service name to the name
		if ( $hr && $hr->{ _dbx('DNS_TYPE') } eq 'SRV' ) {
			$name =
			  $stab->b_dropdown( $opts, $hr, 'DNS_SRV_SERVICE',
				'DNS_RECORD_ID', 1 )
			  . $stab->b_nondbdropdown( $opts, $hr, 'DNS_SRV_PROTOCOL',
				'DNS_RECORD_ID' )
			  . $name;

			$opts->{-class} = 'srvnum';
			$value =
			  $stab->b_textfield( $opts, $hr, 'DNS_PRIORITY', 'DNS_RECORD_ID' )
			  . $stab->b_textfield( $opts, $hr, 'DNS_SRV_WEIGHT',
				'DNS_RECORD_ID' )
			  . $stab->b_textfield( $opts, $hr, 'DNS_SRV_PORT',
				'DNS_RECORD_ID' )
			  . $value;
			delete( $opts->{-class} );
		} elsif ( $hr && $hr->{ _dbx('DNS_TYPE') } eq 'MX' ) {
			$opts->{-class} = 'srvnum';
			$value =
			  $stab->b_textfield( $opts, $hr, 'DNS_PRIORITY', 'DNS_RECORD_ID' )
			  . $value;
			delete( $opts->{-class} );
		}

		if ($hr) {
			$args->{'-id'} = $hr->{ _dbx('DNS_RECORD_ID') };
		} else {
			$args->{'-id'} = "0";
		}
	} else {    # uneditable.
		$ttl = "";
	}
	return $cgi->Tr(
		$args,
		$cgi->td( $hidden, $enablebox ),
		$cgi->td( { -class => 'DNS_NAME' }, $name ),
		$cgi->td($ttl),
		$cgi->td($class),
		$cgi->td($type),
		$cgi->td($value),
		$cgi->td( { -class => 'ptrtd' }, $ptrbox ),
		$cgi->td($excess)
	);
}

sub dump_zone {
	my ( $stab, $dnsdomainid, $dnsrecid ) = @_;
	my $cgi = $stab->cgi || die "Could not create cgi";

	my @limit;

	if ( !$dnsdomainid ) {
		if ( !$dnsrecid ) {
			return $stab->error_return("Must specify a domain to examine");
		}
		my $dns = $stab->get_dns_record_from_id($dnsrecid);
		if ( !$dns ) {
			return $stab->error_return(
				"Must specify a valid record to examine");
		}
		$dnsdomainid = $dns->{ _dbx('DNS_DOMAIN_ID') };
	}

	if ($dnsdomainid) {
		push( @limit, "dns_domain_id = :dns_domain_id" );
	}

	my $q = qq{
		select 	dns_domain_id,
			soa_name,
			soa_class,
			soa_ttl,
			soa_serial,
			soa_refresh,
			soa_retry,
			soa_expire,
			soa_minimum,
			soa_mname,
			soa_rname,
			should_generate,
			parent_dns_domain_id,
			parent_soa_name,
			last_generated
		  from	dns_domain d1
				left join (select dns_domain_id as parent_dns_domain_id,
						soa_name as parent_soa_name from dns_domain) d2 USING 
					(parent_dns_domain_id)
	};
	if ( scalar @limit ) {
		$q .= "WHERE " . join( "\nAND ", @limit );
	}
	my $sth = $stab->prepare($q) || return $stab->return_db_err;

	if ($dnsdomainid) {
		$sth->bind_param( ':dns_domain_id', $dnsdomainid )
		  || return $stab->return_db_err();
	}

	$sth->execute || return $stab->return_db_err($sth);

	my $hr = $sth->fetchrow_hashref;
	$sth->finish;

	if ( !defined($hr) ) {
		$stab->error_return("Unknown Domain");
	}

	my $title = $hr->{ _dbx('SOA_NAME') };
	if ($dnsrecid) {
		$title .= " [ RECORD LIMITED ] ";
	}
	$title .= " (Auto Generated) "
	  if ( $hr->{ _dbx('SHOULD_GENERATE') } eq 'Y' );

	print $cgi->header( { -type => 'text/html' } ), "\n";
	print $stab->start_html( { -title => $title, -javascript => 'dns' } ), "\n";
	print $cgi->start_form( { -action => "write/update_domain.pl" } );
	print $cgi->hidden(
		-name    => 'DNS_DOMAIN_ID',
		-default => $hr->{ _dbx('DNS_DOMAIN_ID') }
	);

	my $lastgen = 'never';
	if ( defined( $hr->{ _dbx('LAST_GENERATED') } ) ) {
		$lastgen = $hr->{ _dbx('LAST_GENERATED') };
	}

	my $soatable = "";
	my $parlink;
	my $zonelink = "";

	$parlink = $cgi->span( $cgi->b("Parent: ") . $parlink ) if($parlink);
	my $nblink = build_reverse_association_section( $stab, $dnsdomainid );
	if (! $dnsrecid) {
		print $cgi->hr;
		my $t =  $cgi->Tr( $cgi->td("Last Generated: $lastgen") );
		my $autogen = "";
		if ( $hr->{ _dbx('SHOULD_GENERATE') } eq 'Y' ) {
			$autogen = "Turn Off Autogen";
		} else {
			$autogen = "Turn On Autogen";
		}
		$t .= $cgi->Tr(
			{ -align => 'center' },
			$cgi->td(
				$cgi->submit(
					{
						-align => 'center',
						-name  => "AutoGen",
						-value => $autogen
					}
				)
			)
		);
		print $cgi->table({-class => 'dnsgentable'}, $t );

		$parlink = "--none--";
		if ( $hr->{ _dbx('PARENT_DNS_DOMAIN_ID') } ) {
			my $url =
		  	build_dns_link( $stab, $hr->{ _dbx('PARENT_DNS_DOMAIN_ID') } );
		my $parent =
		  ( $hr->{ _dbx('PARENT_SOA_NAME') } )
		  ? $hr->{ _dbx('PARENT_SOA_NAME') }
		  : "unnamed zone";
		$parlink = $cgi->a( { -href => $url }, $parent );
		}

		if ( $nblink && length($nblink) ) {
			$nblink = $cgi->br($nblink);
		}

		$zonelink = $cgi->br(
			$cgi->a(
				{ -href => "./?dnsdomid=" . $dnsdomainid },
				"full zone: ",
				$hr->{ _dbx('SOA_NAME') }
			)
		);
		print $cgi->hr;
	}

	print $cgi->div( { -class => 'centeredlist' }, $parlink, $nblink,
		$zonelink );

	if ( !$dnsrecid ) {

		print $stab->zone_header( $hr, 'update' );
		print $cgi->submit(
			{
				-class => 'dnssubmit',
				-name  => "SOA",
				-value => "Submit SOA Changes"
			}
		);
		print $cgi->end_form;
	}

	print $cgi->hr;

	#
	# second form, second table
	#
	print $cgi->start_form( { -action => "update_dns.pl" } );
	print $cgi->start_table( { -class => 'dnstable' } );
	print $cgi->hidden(
		-name    => 'DNS_DOMAIN_ID',
		-default => $hr->{ _dbx('DNS_DOMAIN_ID') }
	);

	print $cgi->Tr(
		$cgi->th(
			[ 'Enable', 'Record', 'TTL', 'Class', 'Type', 'Value', 'PTR' ]
		)
	);

	#
	# Records can only be added to the whole zone.  This may not make sense.
	# XXX
	#
	if ( 1 || !$dnsrecid ) {
		print $cgi->Tr(
			$cgi->td({-colspan => '7' },
				$cgi->a(
					{ -href => '#', -class => 'adddnsrec' },
					$cgi->img(
						{
							-src   => '../stabcons/plus.png',
							-alt   => 'Add',
							-title => 'Add',
							-class => 'plusbutton'
						}
					)
				)
			),
		);
	}

	# print build_dns_rec_Tr($stab);
	# this prints
	build_dns_zone( $stab, $hr->{ _dbx('DNS_DOMAIN_ID') }, $dnsrecid, );

	print $cgi->end_table;
	print $cgi->submit(
		{
			-class => 'dnssubmit', 
			-name  => "Records",
			-value => "Submit DNS Record Changes"
		}
	);
	print $cgi->end_form;
}

sub build_reverse_association_section {
	my ( $stab, $domid ) = @_;
	my $cgi = $stab->cgi || die "Could not create cgi";

	my $q = qq{
		select  nbr.netblock_id,
			net_manip.inet_dbtop(nb.ip_address),
			masklen(nb.ip_address)
		  from  dns_record d
			inner join netblock nb
				on nb.netblock_id = d.netblock_id
			left join netblock nbr
				on nbr.ip_address = nb.ip_address
				and masklen(nbr.ip_address) 
					= masklen(nb.ip_address)
				and nbr.netblock_type = 'default'
		 where  d.dns_type = 'REVERSE_ZONE_BLOCK_PTR'
		   and  d.dns_domain_id = ?

	};
	my $sth = $stab->prepare($q) || return $stab->return_db_err();
	$sth->execute($domid) || return $stab->return_db_err($sth);

	#
	# Print a useful /24 if it exists, otherwise, just show
	# what it is.
	#
	my $linkage = "";
	while ( my ( $nbid, $ip, $bits ) = $sth->fetchrow_array ) {
		if ($nbid) {
			$linkage =
			  $cgi->a( { -href => "../netblock/?nblkid=$nbid" }, "$ip/$bits" );
		} else {
			$linkage = "$ip/$bits";
		}
	}
	$linkage = $cgi->b("Reverse Linked Netblock:") . $linkage if ($linkage);
	$sth->finish;
	$linkage;
}

sub build_dns_link {
	my ( $stab, $dnsdomainid ) = @_;
	my $cgi = $stab->cgi || die "Could not create cgi";

	my $n = new CGI($cgi);
	$n->param( 'dnsdomainid', $dnsdomainid );
	$n->self_url;
}
