%define def_php_extdir	/usr/lib/php/extensions
%define php_extdir		%(php-config --extension-dir || echo "%{def_php_extdir}")
%define pear_dir		%(pear5 config-show | grep php_dir | awk '{print $4}')

Summary:   PHP5 SQLite3 database module
Name:      php5-sqlite3
Version:   0.4
Release:   1
License:   Revised BSD license
Group:     Development/Languages
BuildRoot: %{_tmppath}/php4-sqlite3-buildroot
Provides:  php5-sqlite3
Requires:  php, sqlite >= 3.1
BuildRequires:  php, php5-devel, sqlite-devel >= 3.1
Source:    %{name}-%{version}.tar.gz

%description
PHP5 SQLite3 database module

%prep

# Clean old sources and unpack SOURCE tar file in BUILD dir
%setup -q

%{_prefix}/bin/phpize

%build

%configure
make && strip -g modules/*.so

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

make install INSTALL_ROOT=$RPM_BUILD_ROOT INSTALL_IT="echo "
install -m 755 -d $RPM_BUILD_ROOT/%{pear_dir}/DB
install -m 644 DB/sqlite3.php $RPM_BUILD_ROOT/%{pear_dir}/DB/sqlite3.php

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc ChangeLog COPYING EXPERIMENTAL README examples/*
%{php_extdir}/sqlite3.so
%{pear_dir}/DB/sqlite3.php

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%changelog
* Sun Mar 19 2006 Michiel van Leening <leening@koderz.org>
- Created specfile fo package

