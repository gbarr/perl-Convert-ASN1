#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..12\n"; # This testcase needs more tests

btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
 integer INTEGER OPTIONAL,
 str STRING
)) or warn $asn->error;

$result = pack("C*", 0x4, 0x3, ord('a'), ord('b'), ord('c'));
stest 3, $result, $asn->encode(str => "abc") or warn $asn->error;
btest 4, $ret = $asn->decode($result) or warn $asn->error;
stest 5, "abc", $ret->{str};
btest 6, !exists $ret->{integer};

$result = pack("C*", 0x2, 0x1, 0x9, 0x4, 0x3, ord('a'), ord('b'), ord('c'));
stest 7, $result, $asn->encode(integer => 9, str => "abc") or warn $asn->error;
btest 8, $ret = $asn->decode($result) or warn $asn->error;
stest 9, "abc", $ret->{str};
btest 10, exists $ret->{integer};
ntest 11, 9, $ret->{integer};

btest 12, not( $asn->encode(integer => 9));
