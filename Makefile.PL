# -*- perl -*-

use inc::Module::Install;

name('Convert-ASN1');
abstract('Convert between perl data structures and ASN.1 encoded packets');
author('Graham Barr <gbarr@cpan.org>');
version_from('lib/Convert/ASN1.pm');
license('perl');

clean_files(qw(y.tab.pl));

include_deps('Test::More', 5.004);

check_nmake();      # check and download nmake.exe for Win32

&Makefile->write;
&Meta->write;

sub MY::postamble {

  return <<POSTAMBLE;

distdir : distsign

run_byacc:
	\$(PERL) mkparse parser.y lib/Convert/ASN1/parser.pm

POSTAMBLE

}

