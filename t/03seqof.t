#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

BEGIN { require 't/funcs.pl' }

use Convert::ASN1;

print "1..16\n";

btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare(' ints SEQUENCE OF INTEGER ');

$result = pack("C*", 0x30, 0x0C, 0x02, 0x01, 0x09, 0x02, 0x01, 0x05,
		     0x02, 0x01, 0x03, 0x02, 0x01, 0x01);

stest 3, $result, $asn->encode(ints => [9,5,3,1]);
btest 4, $ret = $asn->decode($result);
btest 5, exists $ret->{'ints'};
stest 6, "9:5:3:1", join(":", @{$ret->{'ints'}});

##
##
##

$result = pack("C*",
  0x30, 0x25,
    0x30, 0x11,
      0x04, 0x04, ord('f'), ord('r'), ord('e'), ord('d'),
      0x30, 0x09,
	0x04, 0x01, ord('a'),
	0x04, 0x01, ord('b'),
	0x04, 0x01, ord('c'),
    0x30, 0x10,
      0x04, 0x03, ord('j'), ord('o'), ord('e'),
      0x30, 0x09,
	0x04, 0x01, ord('q'),
	0x04, 0x01, ord('w'),
	0x04, 0x01, ord('e'),
);

btest 7, $asn->prepare(' seq SEQUENCE OF SEQUENCE { str STRING, val SEQUENCE OF STRING } ')
  or warn $asn->error;
stest 8, $result, $asn->encode(
		seq => [
		  { str => 'fred', val => [qw(a b c)] },
		  { str => 'joe',  val => [qw(q w e)] }
		]);

btest 9, $ret = $asn->decode($result);
ntest 10, 1, scalar keys %$ret;
btest 11, exists $ret->{'seq'};
ntest 12, 2, scalar @{$ret->{'seq'}};
stest 13, 'fred', $ret->{'seq'}[0]{'str'};
stest 14, 'joe', $ret->{'seq'}[1]{'str'};
stest 15, "a:b:c", join(":", @{$ret->{'seq'}[0]{'val'}});
stest 16, "q:w:e", join(":", @{$ret->{'seq'}[1]{'val'}});

