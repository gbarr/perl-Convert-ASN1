
package Convert::ASN1;

# $Id: _encode.pm,v 1.2 2000/05/11 09:22:34 gbarr Exp $

BEGIN {
  local $SIG{__DIE__};
  eval { require bytes } and 'bytes'->import
}

# These are the subs which do the encoding, they are called with
# 0      1    2       3     4     5
# $opt, $op, $stash, $var, $buf, $loop
# The order in the array must match the op definitions above

my @encode = (
  sub { die "internal error\n" },
  \&_enc_boolean,
  \&_enc_integer,
  \&_enc_bitstring,
  \&_enc_string,
  \&_enc_null,
  \&_enc_object_id,
  \&_enc_real,
  \&_enc_sequence,
  \&_enc_sequence, # SET is the same encoding as sequence
  \&_enc_time,
  \&_enc_time,
  \&_enc_utf8,
  \&_enc_any,
  \&_enc_choice
);


sub _encode {
  my $optn  = shift;
  my $ops   = shift;
  my $stash = shift;

  foreach my $op (@{$ops}) {
    if (defined(my $opt = $op->[cOPT])) {
      next unless defined $stash->{$opt};
    }
    foreach my $var (defined($op->[cVAR]) ? $stash->{$op->[cVAR]} : undef) {
      $_[0] .= $op->[cTAG];

      die $op->[cVAR] unless defined($var) || !defined($op->[cVAR]);

      &{$encode[$op->[cTYPE]]}(
	$optn,
	$op,
	$stash,
	$var,
	$_[0],
	$op->[cLOOP]
      );

    }
  }

  $_[0];
}


sub _enc_boolean {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  $_[4] .= pack("CC",1, $_[3] ? 0xff : 0);
}


sub _enc_integer {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  my $neg = ($_[3] < 0);
  my $len = num_length($neg ? ~ $_[3] : $_[3]);
  my $msb = $_[3] & (0x80 << (($len - 1) * 8));

  $len++ if $neg ? !$msb : $msb;

  $_[4] .= asn_encode_length($len);
  $_[4] .= substr(pack("N",$_[3]), -$len);
}


sub _enc_bitstring {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  if (ref($_[3])) {
    my $less = (8 - ($_[3]->[1] & 7)) & 7;
    my $len = ($_[3]->[1] + 7)/8;
    $_[4] .= asn_encode_length(1+$len);
    $_[4] .= chr($less);
    $_[4] .= substr($_[3]->[0], 0, $len);
    if ($less && $len) {
      substr($_[4],-1) &= chr(0xff << $less);
    }
  }
  else {
    $_[4] .= asn_encode_length(1+length $_[3]);
    $_[4] .= chr(0);
    $_[4] .= $_[3];
  }
}


sub _enc_string {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  $_[4] .= asn_encode_length(length $_[3]);
  $_[4] .= $_[3];
}


sub _enc_null {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  $_[4] .= chr(0);
}


sub _enc_object_id {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  my @data = ($_[3] =~ /(\d+)/g);

  if(@data < 2) {
      @data = (0);
  }
  else {
      my $first = $data[1] + ($data[0] * 40);
      splice(@data,0,2,$first);
  }

  my $l = length $_[4];
  $_[4] .= pack("cw*", 0, @data);
  substr($_[4],$l,1) = asn_encode_length(length($_[4]) - $l - 1);
}


sub _enc_real {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  # Zero
  unless ($_[3]) {
    $_[4] .= chr(0);
    return;
  }

  require POSIX;

  # +oo (well we use HUGE_VAL as Infinity is not avaliable to perl)
  if ($_[3] >= POSIX::HUGE_VAL()) {
    $_[4] .= pack("C*",0x01,0x40);
    return;
  }

  # -oo (well we use HUGE_VAL as Infinity is not avaliable to perl)
  if ($_[3] <= - POSIX::HUGE_VAL()) {
    $_[4] .= pack("C*",0x01,0x41);
    return;
  }

  if (exists $_[0]->{'encode_real'} && $_[0]->{'encode_real'} ne 'binary') {
    my $tmp = sprintf("%g",$_[3]);
    $_[4] .= asn_encode_length(1+length $tmp);
    $_[4] .= chr(1); # NR1?
    $_[4] .= $tmp;
    return;
  }

  # We have a real number.
  my $first = 0x80;
  my($mantissa, $exponent) = POSIX::frexp($_[3]);

  if ($mantissa < 0.0) {
    $mantissa = -$mantissa;
    $first |= 0x40;
  }
  my($eMant,$eExp);

  for (1..4) {
    my $int;
    ($mantissa, $int) = POSIX::modf($mantissa * (1<<16));
    $eMant .= pack("n", $int);
  }
  $eMant =~ s/\x00+\z//; # remove trailing zero bytes
  $exponent -= 8 * length $eMant;

  _enc_integer(undef, undef, undef, $exponent, $eExp);

  # $eExp will br prefixed by a length byte
  
  if (5 > length $eExp) {
    $eExp =~ s/\A.//s;
    $first |= length($eExp)-1;
  }
  else {
    $first |= 0x3;
  }

  $_[4] .= asn_encode_length(1 + length($eMant) + length($eExp));
  $_[4] .= chr($first);
  $_[4] .= $eExp;
  $_[4] .= $eMant;
}


sub _enc_sequence {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  if (my $ops = $_[1]->[cCHILD]) {
    my $l = length $_[4];
    $_[4] .= "\0\0"; # guess
    if (defined $_[5]) {
      my $op   = $ops->[0]; # there should only be one
      my $enc  = $encode[$op->[cTYPE]];
      my $tag  = $op->[cTAG];
      my $loop = $op->[cLOOP];

      foreach my $var (@{$_[3]}) {
	$_[4] .= $tag;

	&{$enc}(
	  $_[0], # $optn
	  $op,   # $op
	  $_[2], # $stash
	  $var,  # $var
	  $_[4], # $buf
	  $loop  # $loop
	);
      }
    }
    else {
      _encode($_[0],$_[1]->[cCHILD], defined($_[3]) ? $_[3] : $_[2] , $_[4]);
    }
    substr($_[4],$l,2) = asn_encode_length(length($_[4]) - $l - 2);
  }
  else {
    $_[4] .= asn_encode_length(length $_[3]);
    $_[4] .= $_[3];
  }
}


sub _enc_time {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  my @time;
  my $offset;
  my $isgen = $_[1]->[cTYPE] == opGTIME;

  if (ref($_[3])) {
    $offset = int($_[3]->[1] / 60);
    @time = gmtime($_[3]->[0] + $offset*60);
  }
  elsif (exists $_[0]->{'encode_timezone'}) {
    $offset = int($_[0]->{'encode_timezone'} / 60);
    @time = gmtime($_[3] + $offset*60);
  }
  else {
    @time = localtime($_[3]);
    my @g = gmtime($_[3]);
    
    $offset = ($time[1] - $g[1]) + ($time[2] - $g[2]) * 60;
    my $d = $time[7] - $g[7];
    if($d == 1 || $d < -1) {
      $offset += 1440;
    }
    elsif($d > 1) {
      $offset -= 1440;
    }
  }
  $time[4] += 1;
  $time[5] = $isgen ? $time[5] + 1900 : $time[5] % 100;
  $_[4] .= sprintf("%02d"x6, @time[5,4,3,2,1,0]);
  if ($isgen) {
    my $sp = sprintf("%.03f",ref($_[3]) ? $_[3]->[1] : $_[3]);
    $_[4] .= substr($sp,-4) unless $sp =~ /\.000$/;
  }
  $_[4] .= $offset ? sprintf("%+03d%02d",$offset / 60, abs($offset % 60)) : 'Z';
}


sub _enc_utf8 {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  $_[4] .= asn_encode_length(length $_[3]);
  $_[4] .= $_[3];
}


sub _enc_any {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  $_[4] .= $_[3];
}


sub _enc_choice {
# 0      1    2       3     4     5
# $optn, $op, $stash, $var, $buf, $loop

  my $stash = defined($_[3]) ? $_[3] : $_[2];
  for my $op (@{$_[1]->[cCHILD]}) {
    my $var = $op->[cVAR];
    if (exists $stash->{$var}) {
      _encode($_[0],[$op], $stash, $_[4]);
      last;
    }
  }
}


1;

