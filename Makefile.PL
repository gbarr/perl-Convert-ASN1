# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.1 2000/05/03 12:24:43 gbarr Exp $

use 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM  => 'lib/Convert/ASN1.pm',
  NAME          => 'Convert::ASN1',
  AUTHOR    	=> 'Graham Barr <gbarr@pobox.com>',
  ABSTRACT  	=> 'Convert between perl data structures and ASN.1 encoded packets',
  clean         => { FILES => 'y.tab.pl' },
);

sub MY::postamble {

  my $ppd = $] >= 5.00503 ? 'ppd' : '';
  my $mkhtml = "../bin/mkhtml";
  my $html = '';

  if ( -x $mkhtml ) {
    $mkhtml = <<EDQ;
mkhtml :
	$mkhtml
EDQ
    $html = 'mkhtml';
  }
  else { $mkhtml = '' }

  return '' unless length($ppd.$html);

<<"EDQ";

distdir : $ppd $html

$mkhtml

run_byacc:
	\$(PERL) mkparse parser.y lib/Convert/ASN1/parser.pm

EDQ
}

