
package Convert::ASN1;

# $Id: _decode.pm,v 1.5 2001/04/19 22:52:10 gbarr Exp $

BEGIN {
  local $SIG{__DIE__};
  eval { require bytes } and 'bytes'->import
}

# These are the subs that do the decode, they are called with
# 0      1    2       3     4
# $optn, $op, $stash, $var, $buf
# The order must be the same as the op definitions above

my @decode = (
  sub { die "internal error\n" },
  \&_dec_boolean,
  \&_dec_integer,
  \&_dec_bitstring,
  \&_dec_string,
  \&_dec_null,
  \&_dec_object_id,
  \&_dec_real,
  \&_dec_sequence,
  \&_dec_set,
  \&_dec_time,
  \&_dec_time,
  \&_dec_utf8,
  undef, # ANY
  undef, # CHOICE
);


sub _decode {
  my $optn  = shift;
  my $ops = shift;
  my $stash = shift;
  my $pos = shift;
  my $end = shift;
  my $larr = $_[2] || [];

  # we try not to copy the input buffer at any time
  foreach my $buf ($_[0]) {
    OP:
    foreach my $op (@{$ops}) {
      my $var;
      my @arr;
      my $idx = defined($var = $_[1])
			? (($stash->{$var} = \@arr),0)
			: (($var = $op->[cVAR]),-99);

      if (length $op->[cTAG]) {

	TAGLOOP: {
	  my($tag,$len,$npos,$indef) = _decode_tl($buf,$pos,$end,$larr)
	    or do {
	      next OP if $pos==$end and ($idx >= 0 || defined $op->[cOPT]);
	      die "decode error";
	    };

	  if ($tag ne $op->[cTAG]) {
	    if ($idx >= 0 || defined $op->[cOPT]) {
	      unshift @$larr, $len if $indef;
	      next OP;
	    }
	    die "decode error " . unpack("H*",$tag) ."<=>" . unpack("H*",$op->[cTAG]);
	  }

	  &{$decode[$op->[cTYPE]]}(
	    $optn,
	    $op,
	    $stash,
	    # We send 1 if there is not var as if there is the decode
	    # should be getting undef. So if it does not get undef
	    # it knows it has no variable
	    (($idx >= 0) ? $arr[$idx++] : defined($var) ? $stash->{$var} : 1),
	    $buf,$npos,$len,$larr
	  );

	  $pos = $npos+$len+$indef;

	  redo TAGLOOP if $idx >= 0 && $pos < $end;
        }
      }
      else { # opTag length is zero, so it must be an ANY or CHOICE
	
	if ($op->[cTYPE] == opANY) {

	  ANYLOOP: {

	    my($tag,$len,$npos,$indef) = _decode_tl($buf,$pos,$end,$larr)
	      or do {
		next OP if $pos==$end and ($idx >= 0 || defined $op->[cOPT]);
		die "decode error";
	      };

	    $len += $npos-$pos;

	    (($idx >= 0) ? $arr[$idx++] : $stash->{$var})
	      = substr($buf,$pos,$len);

	    $pos += $len + $indef;

	    redo ANYLOOP if $idx >= 0 && $pos < $end;
	  }
	}
	else {

	  CHOICELOOP: {
	    my($tag,$len,$npos,$indef) = _decode_tl($buf,$pos,$end,$larr)
	      or do {
		next OP if $pos==$end and ($idx >= 0 || defined $op->[cOPT]);
		die "decode error";
	      };
	    foreach my $cop (@{$op->[cCHILD]}) {

	      if ($tag eq $cop->[cTAG]) {

		my $nstash = $idx >= 0
			? ($arr[$idx++]={})
			: defined($var)
				? ($stash->{$var}={}) : $stash;

		&{$decode[$cop->[cTYPE]]}(
		  $optn,
		  $cop,
		  $nstash,
		  $nstash->{$cop->[cVAR]},
		  $buf,$npos,$len,$larr
		);

		$pos = $npos+$len+$indef;

		redo CHOICELOOP if $idx >= 0 && $pos < $end;
		next OP;
	      }
	    }
	  }
	  die "decode error" unless $op->[cOPT];
	}
      }
    }
  }
  die "decode error $pos $end" unless $pos == $end;
}


sub _dec_boolean {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  $_[3] = ord(substr($_[4],$_[5],1)) ? 1 : 0;
  1;
}


sub _dec_integer {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  my $buf = substr($_[4],$_[5],$_[6]);
  my $tmp = ord($buf) & 0x80 ? chr(255) : chr(0);
  if ($_[6] > 4) {
      $_[3] = os2ip($tmp x (4-$_[6]) . $buf, $_[0]->{decode_bigint} || 'Math::BigInt');
  } else {
      # N unpacks an unsigned value
      $_[3] = unpack("l",pack("l",unpack("N", $tmp x (4-$_[6]) . $buf)));
  }
  1;
}


sub _dec_bitstring {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  $_[3] = [ substr($_[4],$_[5]+1,$_[6]-1), ($_[6]-1)*8-ord(substr($_[4],$_[5],1)) ];
  1;
}


sub _dec_string {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  $_[3] = substr($_[4],$_[5],$_[6]);
  1;
}


sub _dec_null {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  $_[3] = 1;
  1;
}


sub _dec_object_id {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  my @data = unpack("w*",substr($_[4],$_[5],$_[6]));
  splice(@data,0,1,int($data[0]/40),$data[0] % 40) if $data[0];
  $_[3] = join(".", @data);
  1;
}


my @_dec_real_base = (2,8,16);

sub _dec_real {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  $_[3] = 0.0, return unless $_[6];

  my $first = ord(substr($_[4],$_[5],1));
  if ($first & 0x80) {
    # A real number

    require POSIX;

    my $exp;
    my $expLen = $first & 0x3;
    my $estart = $_[5]+1;

    if($expLen == 3) {
      $estart++;
      $expLen = ord(substr($_[4],$_[5]+1,1));
    }
    else {
      $expLen++;
    }
    _dec_integer(undef, undef, undef, $exp, $_[4],$estart,$expLen);

    my $mant = 0.0;
    for (reverse unpack("C*",substr($_[4],$estart+$expLen))) {
      $exp +=8, $mant = (($mant+$_) / 256) ;
    }

    $mant *= 1 << (($first >> 2) & 0x3);
    $mant = - $mant if $first & 0x40;

    $_[3] = $mant * POSIX::pow($_dec_real_base[($first >> 4) & 0x3], $exp);
    return;
  }
  elsif($first & 0x40) {
    $_[3] =   POSIX::HUGE_VAL(),return if $first == 0x40;
    $_[3] = - POSIX::HUGE_VAL(),return if $first == 0x41;
  }
  elsif(substr($_[4],$_[5],$_[6]) =~ /^.([-+]?)0*(\d+(?:\.\d+(?:[Ee][-+]?\d+)?)?)$/s) {
    $_[3] = eval "$1$2";
    return;
  }

  die "REAL decode error\n";
}


sub _dec_sequence {
# 0      1    2       3     4     5     6     7
# $optn, $op, $stash, $var, $buf, $pos, $len, $larr

  if (defined( my $ch = $_[1]->[cCHILD])) {
    _decode(
      $_[0], #optn
      $ch,   #ops
      (defined($_[3]) || $_[1]->[cLOOP]) ? $_[2] : ($_[3]= {}), #stash
      $_[5], #pos
      $_[5]+$_[6], #end
      $_[4], #buf
      $_[1]->[cLOOP] && $_[1]->[cVAR], #loop
      $_[7]
    );
  }
  else {
    $_[3] = substr($_[4],$_[5],$_[6]);
  }
  1;
}


sub _dec_set {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

 die "SET decode not implemented\n";
}


my %_dec_time_opt = ( unixtime => 0, withzone => 1, raw => 2);

sub _dec_time {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  my $mode = $_dec_time_opt{$_[0]->{'decode_time'} || ''} || 0;

  if ($mode == 2) {
    $_[3] = substr($_[4],$_[5],$_[6]);
    return;
  }

  my @bits = (substr($_[4],$_[5],$_[6])
     =~ /^((?:\d\d)?\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)((?:\.\d{1,3})?)(([-+])(\d\d)(\d\d)|Z)/)
     or die "bad time format";

  if ($bits[0] < 100) {
    $bits[0] += 100 if $bits[0] < 50;
  }
  else {
    $bits[0] -= 1900;
  }
  $bits[1] -= 1;
  require Time::Local;
  my $time = Time::Local::timegm(@bits[5,4,3,2,1,0]);
  $time += $bits[6] if length $bits[6];
  my $offset = 0;
  if ($bits[7] ne 'Z') {
    $offset = $bits[9] * 3600 + $bits[10] * 60;
    $offset = -$offset if $bits[8] eq '-';
    $time -= $offset;
  }
  $_[3] = $mode ? [$time,$offset] : $time;
}


sub _dec_utf8 {
# 0      1    2       3     4     5     6
# $optn, $op, $stash, $var, $buf, $pos, $len

  BEGIN {
    local $SIG{__DIE__};
    eval { require bytes } and 'bytes'->unimport;
    eval { require utf8  } and 'utf8'->import;
  }

  $_[3] = (substr($_[4],$_[5],$_[6]) =~ /(.*)/s)[0];
  1;
}


sub _decode_tl {
  my($pos,$end,$larr) = @_[1,2,3];
  my $indef = 0;

  my $tag = substr($_[0], $pos++, 1);

  if((ord($tag) & 0x1f) == 0x1f) {
    my $b;
    my $n=1;
    do {
      $tag .= substr($_[0],$pos++,1);
      $b = ord substr($tag,-1);
    } while($b & 0x80);
  }
  return if $pos >= $end;

  my $len = ord substr($_[0],$pos++,1);

  if($len & 0x80) {
    $len &= 0x7f;

    if ($len) {
      return if $pos+$len > $end ;

      ($len,$pos) = (unpack("N", "\0" x (4 - $len) . substr($_[0],$pos,$len)), $pos+$len);
    }
    else {
      unless (@$larr) {
        _scan_indef($_[0],$pos,$end,$larr) or return;
      }
      $indef = 2;
      $len = shift @$larr;
    }
  }

  return if $pos+$len+$indef > $end;

  ($tag, $len, $pos, $indef);
}

sub _scan_indef {
  my($pos,$end,$larr) = @_[1,2,3];
  @$larr = ();
  my @depth = ( $pos );

  while(@depth) {
    return if $pos+2 > $end;

    if (substr($_[0],$pos,2) eq "\0\0") {
      my $end = $pos;
      $pos = shift @depth;
      unshift @$larr, $end-$pos;
      $pos += 2;
      next;
    }

    my $tag = substr($_[0], $pos++, 1);

    if((ord($tag) & 0x1f) == 0x1f) {
      my $b;
      my $n=1;
      do {
	$tag .= substr($_[0],$pos++,1);
	$b = ord substr($tag,-1);
      } while($b & 0x80);
    }
    return if $pos >= $end;

    my $len = ord substr($_[0],$pos++,1);

    if($len & 0x80) {
      if ($len &= 0x7f) {
	return if $pos+$len > $end ;

	$pos += $len + unpack("N", "\0" x (4 - $len) . substr($_[0],$pos,$len));
      }
      else {
        unshift @depth, $pos;
      }
    }
    else {
      $pos += $len;
    }
  }

  1;
}

1;

