#!/usr/local/bin/perl

#
# Test the use of sequences
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..18\n";


btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
  SEQUENCE {
    integer INTEGER,
    bool BOOLEAN,
    str STRING
  }
)) or warn $asn->error;

my $result = pack("C*", 0x30, 0x10, 0x02, 0x01, 0x01, 0x01, 0x01, 0x00,
			0x04, 0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69,
			0x6E, 0x67
);
stest 3, $result, $asn->encode(integer => 1, bool => 0, str => "A string") or warn $asn->error;
btest 4, $ret = $asn->decode($result) or warn $asn->error;
ntest 5, 1, $ret->{integer};
ntest 6, 0, $ret->{bool};
stest 7, "A string", $ret->{str};

btest 8, $asn->prepare(q(
  seq SEQUENCE {
    integer INTEGER,
    bool BOOLEAN,
    str STRING
  }
)) or warn $asn->error;
stest 9, $result, $asn->encode(seq => { integer => 1, bool => 0, str => "A string" }) or warn $asn->error;
btest 10, $ret = $asn->decode($result) or warn $asn->error;
ntest 11, 1, $ret->{seq}{integer};
ntest 12, 0, $ret->{seq}{bool};
stest 13, "A string", $ret->{seq}{str};


$result = pack("C*", 0x30, 0x16, 0x09, 0x09, 0x80, 0xCB, 0xD8, 0xF5,
                     0xC2, 0x8F, 0x5C, 0x28, 0xF8, 0x09, 0x09, 0x80,
                     0xCC, 0xC5, 0x70, 0xA3, 0xD7, 0x0A, 0x3D, 0x70);

btest 14, $asn->prepare(q(
                        SEQUENCE {
                                real  REAL,
                                real2 REAL
                        }
)) or warn $asn->error;
stest 15, $result, $asn->encode( real => 6.78, real2 => 12.34) or warn $asn->error;
btest 16, $ret = $asn->decode($result) or warn $asn->error;
ntest 17, 6.78,  $ret->{real};
ntest 18, 12.34, $ret->{real2};
