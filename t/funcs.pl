
sub ntest ($$$) {
  my $ret = 1;
  if ($_[1] != $_[2]) {
    my $fmt = (int($_[1]) && $_[1] && ($_[1] > 255 || $_[2] > 255)) ? "0x%x" : "%g";
    printf "#$_[0]: expecting $fmt\n",$_[1];
    printf "#$_[0]:       got $fmt\n",$_[2];
    print "not ";
    $ret = 0;
  }
  print "ok $_[0]\n";
  $ret;
}

sub stest ($$$) {
  my $ret = 1;
  unless (defined $_[2] && $_[1] eq $_[2]) {
    printf "#$_[0]: expecting %s\n", $_[1] =~ /[^\.\d\w]/ ? "hex:".unpack("H*",$_[1]) : $_[1];
    printf "#$_[0]:       got %s\n", defined($_[2]) ? $_[2] =~  /[^\.\d\w]/ ? "hex:".unpack("H*",$_[2]) : $_[2] : 'undef';
    print "not ";
    $ret = 0;
  }
  print "ok $_[0]\n";
  $ret;
}

sub btest ($$) {
  print "not " unless $_[1];
  print "ok $_[0]\n";
  $_[1]
}

1;

