#!/usr/local/bin/perl

#
# Test bigint INTEGER encoding/decoding
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..27\n";

btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare(q(
 integer INTEGER
)) or warn $asn->error;

use Math::BigInt;
my $num = 
Math::BigInt->new("1092509802939879587398450394850984098031948509");

$asn->configure(decode => { bigint => 'Math::BigInt' });

$result = pack("C*", 0x2,  0x13, 0x30, 0xfd, 0x65, 0xc1, 0x01, 0xd9,
                     0xea, 0x2c, 0x94, 0x9e, 0xc5, 0x08, 0x50, 0x4a,
                     0x90, 0x43, 0xdb, 0x52, 0xdd);
stest 3, $result, $asn->encode(integer => $num);
btest 4, $ret = $asn->decode($result);
btest 5, exists $ret->{integer};
btest 6, ref($ret->{integer}) eq 'Math::BigInt';
ntest 7, $num, $ret->{integer};

$num = (1<<17) * (1<<17);
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0x0);
stest 8, $result, $asn->encode(integer => $num);
btest 9, $ret = $asn->decode($result);
btest 10, exists $ret->{integer};
ntest 11, $num, $ret->{integer};

$num += 10;
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0xa);
stest 12, $result, $asn->encode(integer => $num);
btest 13, $ret = $asn->decode($result);
btest 14, exists $ret->{integer};
ntest 15, $num, $ret->{integer};

$num = -$num;
$result = pack("C*", 0x2, 0x5, 0xfb, 0xff, 0xff, 0xff, 0xf6);
stest 16, $result, $asn->encode(integer => $num);
btest 17, $ret = $asn->decode($result);
btest 18, exists $ret->{integer};
ntest 19, $num, $ret->{integer};

$num += 10;
$result = pack("C*", 0x2, 0x5, 0xfc, 0x0, 0x0, 0x0, 0x0);
stest 20, $result, $asn->encode(integer => $num);
btest 21, $ret = $asn->decode($result);
btest 22, exists $ret->{integer};
ntest 23, $num, $ret->{integer};

$num = Math::BigInt->new("-1092509802939879587398450394850984098031948509");
$result = pack("C*", 0x2,  0x13, 0xcf, 0x2,  0x9a, 0x3e, 0xfe, 0x26,
                     0x15, 0xd3, 0x6b, 0x61, 0x3a, 0xf7, 0xaf, 0xb5,
                     0x6f, 0xbc, 0x24, 0xad, 0x23);
stest 24, $result, $asn->encode(integer => $num);
btest 25, $ret = $asn->decode($result);
btest 26, exists $ret->{integer};
ntest 27, $num, $ret->{integer};


