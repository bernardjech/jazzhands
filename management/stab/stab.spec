%define name    jazzhands-stab
%define prefix	/var/www/stab
%define version 0.54.1
%define release 1
Name:   	%{name}
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        JazzHands STAB Web Front End
Group:  	System Environment/Libraries
License:        BSD
URL:    	http://www.jazzhands.net/
Source0:	%{name}.tgz
BuildRoot:      %{_tmppath}/%{name}-root
BuildArch:	noarch
#BuildRequires: 
Requires:      	jazzhands-perl-mgmt, jazzhands-perl-common, jazzhands-perl-stab, jazzhands-javascript-common

%description

System Tools for Administrative Baselining

%package -n jazzhands-perl-stab
group: System Environment/Libraries
Summary: Perl library for STAB
Requires: perl-Net-IP, perl-Net-Netmask, perl-Net-DNS, perl-NetAddr-IP


%description -n jazzhands-perl-stab
Perl libraries for STAB

%prep
%setup -q -n %{name}

echo Nothing to do for web site
echo Building perl modules
cd perl/src && %{__perl} Makefile.PL INSTALLDIRS=vendor --default


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{prefix}
(cd web/src/web ; tar cf - . ) | (cd $RPM_BUILD_ROOT/%{prefix} ; tar xpvf - )

cd perl/src && make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%clean
rm -rf %{buildroot}

%files
%defattr(755,root,root,-)
%{prefix}/sites.pl
%{prefix}/style.pl
%{prefix}/error.pl
%{prefix}/Makefile
%{prefix}/images/Makefile
%{prefix}/images/electric/l6-30p.png
%{prefix}/images/electric/l5-20p.png
%{prefix}/images/electric/6-20p.png
%{prefix}/images/electric/l5-15p.png
%{prefix}/images/electric/5-15p.png
%{prefix}/images/electric/cs8365c.png
%{prefix}/images/electric/iec-60320-c14.png
%{prefix}/images/electric/5-50p.png
%{prefix}/images/electric/9p54u2.png
%{prefix}/images/electric/Makefile
%{prefix}/images/electric/l21-30p.png
%{prefix}/images/electric/6-15p.png
%{prefix}/images/electric/5-30p.png
%{prefix}/images/electric/iec-60320-c20.png
%{prefix}/images/electric/6-50p.png
%{prefix}/images/electric/l15-30p.png
%{prefix}/images/electric/cs8364.png
%{prefix}/images/electric/l6-20p.png
%{prefix}/images/electric/l5-30p.png
%{prefix}/images/electric/l6-15p.png
%{prefix}/images/electric/6-30p.png
%{prefix}/images/electric/5-20p.png
%{prefix}/images/electric/unknown.png
%{prefix}/images/electric/iec-60320-c13.png
%{prefix}/images/electric/dc.png
%{prefix}/images/electric/iec-60320-c19.png
%{prefix}/images/electric/l14-30p.png
%{prefix}/images/development-background.png
%{prefix}/images/vendors/dell.ico
%{prefix}/images/vendors/target.gif
%{prefix}/images/vendors/starred.gif
%{prefix}/images/vendors/google.ico
%{prefix}/images/vendors/juniper.ico
%{prefix}/images/vendors/emc.ico
%{prefix}/images/vendors/Makefile
%{prefix}/images/vendors/hp.ico
%{prefix}/images/vendors/netapp.ico
%{prefix}/images/vendors/sun.ico
%{prefix}/images/vendors/stargold.gif
%{prefix}/images/vendors/force10.ico
%{prefix}/images/vendors/dothill.ico
%{prefix}/images/vendors/cisco.ico
%{prefix}/images/vendors/ibm.ico
%{prefix}/images/vendors/avaya.ico
%{prefix}/images/vendors/foundry.ico
%{prefix}/index.pl
%{prefix}/javascript/dns-utils.js
%{prefix}/javascript/app-utils.js
%{prefix}/javascript/ajax-utils.js
%{prefix}/javascript/Makefile
%{prefix}/javascript/table-manip.js
%{prefix}/javascript/devicetype.js
%{prefix}/javascript/tickets.js
%{prefix}/javascript/ajaxsearch.js
%{prefix}/javascript/racks.js
%{prefix}/javascript/netblock.js
%{prefix}/javascript/device-utils.js
%{prefix}/javascript/stab-common.js
%{prefix}/circuit/index.pl
%{prefix}/circuit/trunkgroup/index.pl
%{prefix}/stabcons/Makefile
%{prefix}/stabcons/stab.png
%{prefix}/stabcons/collapse.jpg
%{prefix}/stabcons/expand.jpg
%{prefix}/stabcons/progress.gif
%{prefix}/device/type/Makefile
%{prefix}/device/type/index.pl
%{prefix}/device/type/dtsearch.pl
%{prefix}/device/type/write/updatedt.pl
%{prefix}/device/type/write/Makefile
%{prefix}/device/type/write/.htaccess
%{prefix}/device/type/write/adddt.pl
%{prefix}/device/os/search.pl
%{prefix}/device/os/Makefile
%{prefix}/device/os/report.pl
%{prefix}/device/os/index.pl
%{prefix}/device/os/write/Makefile
%{prefix}/device/os/write/.htaccess
%{prefix}/device/os/write/updateos.pl
%{prefix}/device/ajax-devsearch.pl
%{prefix}/device/device.pl
%{prefix}/device/search.pl
%{prefix}/device/voe/voecompare.pl
%{prefix}/device/voe/pkg.pl
%{prefix}/device/voe/search.pl
%{prefix}/device/voe/Makefile
%{prefix}/device/voe/voesymtrax.pl
%{prefix}/device/voe/index.pl
%{prefix}/device/voe/write/Makefile
%{prefix}/device/voe/write/.htaccess
%{prefix}/device/apps/Makefile
%{prefix}/device/apps/index.pl
%{prefix}/device/Makefile
%{prefix}/device/index.pl
%{prefix}/device/snmp/Makefile
%{prefix}/device/snmp/index.pl
%{prefix}/device/snmp/.htaccess
%{prefix}/device/snmp/commit_change.pl
%{prefix}/device/device-ajax.pl
%{prefix}/device/certs/Makefile
%{prefix}/device/certs/index.pl
%{prefix}/device/certs/write/Makefile
%{prefix}/device/write/update_device.pl
%{prefix}/device/write/Makefile
%{prefix}/device/write/.htaccess
%{prefix}/device/write/add_device.pl
%{prefix}/sites/racks/Makefile
%{prefix}/sites/racks/index.pl
%{prefix}/sites/racks/write/Makefile
%{prefix}/sites/Makefile
%{prefix}/sites/index.pl
%{prefix}/sites/rackit.pl
%{prefix}/sites/write/retire_site.pl
%{prefix}/sites/write/Makefile
%{prefix}/sites/blockmgr.pl
%{prefix}/netblock/ipalloc/allocate_ip.pl
%{prefix}/netblock/ipalloc/Makefile
%{prefix}/netblock/ipalloc/.htaccess
%{prefix}/netblock/search.pl
%{prefix}/netblock/Makefile
%{prefix}/netblock/index.pl
%{prefix}/netblock/dhcprange.pl
%{prefix}/netblock/write/rmnetblock.pl
%{prefix}/netblock/write/doadd.pl
%{prefix}/netblock/write/addnetblock.pl
%{prefix}/netblock/write/edit_netblock.pl
%{prefix}/netblock/write/Makefile
%{prefix}/netblock/write/.htaccess
%{prefix}/dns/addazone.pl
%{prefix}/dns/dns-reconcile.pl
%{prefix}/dns/search.pl
%{prefix}/dns/Makefile
%{prefix}/dns/index.pl
%{prefix}/dns/update_dns.pl
%{prefix}/dns/db-reconcile.pl
%{prefix}/dns/dns-debug.pl
%{prefix}/dns/write/add_domain.pl
%{prefix}/dns/write/Makefile
%{prefix}/dns/write/.htaccess
%{prefix}/dns/write/update_domain.pl
%{prefix}/dns/soacheck.pl
%{prefix}/dns/dns-ajax.pl

%files -n jazzhands-perl-stab
##  %doc Changes README
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Fri Sep 27 2013 Todd Kover <kovert@omniscient.com> 0.54.1-1
- use jquery more
- fix b_nondbdropdown to work in postgresql world
- migrate edit button to jquery implementation
- manage should_generate_ptr from dns tab
- fix a record changing
- overhaul SRV record management
- NOTE: deleting the last ptr record does NOT move the PTR record..
- give error back to user if it happened on commit
* Wed Sep 25 2013 Todd Kover <kovert@omniscient.com> 0.54-1
- migrate network_interface.v4_netblock_id to netblock_id
* Mon May  6 2013 Todd Kover <kovert@omniscient.com> 0.52.7-1
- dns: improve add/update of netblocks of type dns
* Mon May  6 2013 Todd Kover <kovert@omniscient.com> 0.52.6-1
- dns-reconcile: improve SRV checks
* Mon May  6 2013 Todd Kover <kovert@omniscient.com> 0.52.5-1
- dns-reconcile: improve SRV checks
- dns-reconcile: do not compare A records to ipv6 records
* Fri May  3 2013 Todd Kover <kovert@omniscient.com> 0.52.4-1
  - remove debug statements that leaked in
  - sort dns records in drop downs with in-addr after others
  - fix dns changes to actaully clear params and have minimal url
  - handle DNS that points to things that are not normal blocks
* Fri Apr 19 2013 Todd Kover <kovert@omniscient.com> 0.52.3-1
 - imporve dns reconciliation for mx and ns records
* Fri Apr 19 2013 Todd Kover <kovert@omniscient.com> 0.52.2-1
 - minor dns and netblock fixes
* Thu Mar  7 2013 Todd Kover <kovert@omniscient.com> 0.52-1
 - fix mx/srv records when they are assigned to work on zone
 - much more liberal use of JH::Common::Util
 - many improvements to dns,netblocks
* Wed Mar  6 2013 Todd Kover <kovert@omniscient.com> 0.2.7.1-1
 - fix site syntax errors when looking at an individual site
* Mon Aug 27 2012 Todd Kover <kovert@omniscient.com> 0.2.7.0-1
 - add basic support for mysql
* Mon Aug 27 2012 Todd Kover <kovert@omniscient.com> 0.2.7.0-1
 - initial release

