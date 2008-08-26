# -*- perl -*-

use inc::Module::Install;

perl_version    5.005;

name         'Convert-ASN1';
abstract     'Convert between perl data structures and ASN.1 encoded packets';
author       'Graham Barr <gbarr@cpan.org>';
version_from 'lib/Convert/ASN1.pm';
license      'perl';
sign         1;

repository   'git://git.goingon.net/Convert-ASN1.git';

clean_files  qw(y.tab.pl);

include_deps 'Test::More';

check_nmake;      # check and download nmake.exe for Win32

auto_install_now;

WriteAll;
