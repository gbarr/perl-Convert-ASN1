#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..12\n"; # This testcase needs more tests

btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare(q(
 int INTEGER OPTIONAL,
 str STRING
)) or warn $asn->error;

$result = pack("C*", 0x4, 0x3, ord('a'), ord('b'), ord('c'));
stest 3, $result, $asn->encode(str => "abc");
btest 4, $ret = $asn->decode($result);
stest 5, "abc", $ret->{str};
btest 6, !exists $ret->{int};

$result = pack("C*", 0x2, 0x1, 0x9, 0x4, 0x3, ord('a'), ord('b'), ord('c'));
stest 7, $result, $asn->encode(int => 9, str => "abc");
btest 8, $ret = $asn->decode($result);
stest 9, "abc", $ret->{str};
btest 10, exists $ret->{int};
ntest 11, 9, $ret->{int};

btest 12, not( $asn->encode(int => 9));
