#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..21\n";

btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare(q(
  int [0] INTEGER
));

$result = pack("C*", 0x80, 0x01, 0x08);
stest 3, $result, $asn->encode(int => 8);
btest 4, $ret = $asn->decode($result);
ntest 5, 8, $ret->{int};

btest 6, $asn->prepare(q(
  int [APPLICATION 1] INTEGER
));

$result = pack("C*", 0x41, 0x01, 0x08);
stest 7, $result, $asn->encode(int => 8);
btest 8, $ret = $asn->decode($result);
ntest 9, 8, $ret->{int};

btest 10, $asn->prepare(q(
  int [CONTEXT 2] INTEGER
));

$result = pack("C*", 0x82, 0x01, 0x08);
stest 11, $result, $asn->encode(int => 8);
btest 12, $ret = $asn->decode($result);
ntest 13, 8, $ret->{int};

btest 14, $asn->prepare(q(
  int [UNIVERSAL 3] INTEGER
));

$result = pack("C*", 0x03, 0x01, 0x08);
stest 15, $result, $asn->encode(int => 8);
btest 16, $ret = $asn->decode($result);
ntest 17, 8, $ret->{int};

btest 18, $asn->prepare(q(
  int [PRIVATE 4] INTEGER
));

$result = pack("C*", 0xc4, 0x01, 0x08);
stest 19, $result, $asn->encode(int => 8);
btest 20, $ret = $asn->decode($result);
ntest 21, 8, $ret->{int};

