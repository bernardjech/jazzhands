%define	prefix	/usr
%define	zgroot	libexec/jazzhands/zonegen

Summary:    jazzhands-zonegen-client - generates and pushes out zones
Vendor:     JazzHands
Name:       jazzhands-zonegen-client
Version:    __VERSION__
Release:    1
License:    Unknown
Group:      System/Management
Url:        http://www.jazzhands.net/
BuildArch:  noarch
Source0:    %{name}-%{version}.tar.gz
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildArch:  noarch
Requires:   jazzhands-perl-common, perl-JazzHands-DBI, perl-Net-IP, bind
# bind is there for named-checkzone


%description
Deals with zonegen on nameservers that receive zones


%prep
%setup -q -n %{name}-%{version}
make -f Makefile.jazzhands

%install
make -f Makefile.jazzhands DESTDIR=%{buildroot} PREFIX=%{prefix}/%{zgroot} install

%clean
make -f Makefile.jazzhands DESTDIR=%{buildroot} clean


%files
%defattr(755,root,root,-)
%{prefix}/%{zgroot}/ingest-zonegen-changes
