use Test::More tests => 24;

use strict;
use warnings;

use lib 't/';
use IO::File;

require Module::Locate;

Module::Locate->import('locate');

# no. 1
can_ok(__PACKAGE__, 'locate');

my($test_mod, $test_fn) = qw( MLtest::hereiam t/MLtest/hereiam.pm );

{
  my $path;
  eval { $path = locate($test_mod) };
  
  # no. 2, 3, 4
  warn "no. 2: $@" if $@;
  ok( $@ eq '', "locate had no errors");
  ok( defined $path, "\$path was assigned something");
  like( $path, qr{\Q$test_fn\E\z},
        "module found in predicted place: $path");

  shift @INC;
  local $@;
  undef $path;

  eval { $path = locate($test_mod) };

  # no. 5, 6
  ok( $@, "\$@ was set");
  like( $@, qr/Can't locate/, "found expected error message");
}

{
  unshift @INC => sub {
    open(my $fh, '<', $test_fn) or die "ack: $! [$test_fn]\n";
    $fh
  };

  # no. 7, 8
  my $f;
  ok( $f = locate($test_mod), 'simple FH coderef in INC' );
  ok( Module::Locate::acts_like_fh($f), "$f is deigned to be a filehandle");
  
  close $f;

  $INC[0] = sub { IO::File->new($test_fn) };
  
  # no. 9, 10
  ok( $f = locate($test_mod), 'IO::File coderef in INC');
  ok( Module::Locate::acts_like_fh($f), "$f is deigned to be a filehandle");

  close $f;

  $INC[0] = sub { bless [], 'MLtest::iohandle' };
  
  # no. 11, 12
  ok( $f = locate($test_mod), 'IO::Handle object coderef in INC');
  ok( Module::Locate::acts_like_fh($f), "$f is deigned to be a filehandle");

  $INC[0] = sub { bless [], 'MLtest::overloaded' };
  
  # no. 13, 14
  ok( $f = locate($test_mod), 'overloaded object coderef in INC');
  ok( Module::Locate::acts_like_fh($f), "$f is deigned to be a filehandle");

  $INC[0] = sub { bless [], 'MLtest::nought' };
  
  undef $f;
  # no. 15, 16
  eval { $f = locate($test_mod) };
  like( $@, qr/invalid \@INC/, 'b0rken object coderef in INC');
  ok( !defined($f), "\$f is not a filehandle");
}

{
  $INC[0] = [ sub { IO::File->new($test_fn) } ];
  
  my $f;

  # no. 17, 18
  ok( $f = locate($test_mod), 'IO::File arrayrefin INC');
  ok( Module::Locate::acts_like_fh($f), "$f is deigned to be a filehandle");

  close $f;
  $INC[0] = [ sub { "fooey" } ];
  undef $f;

  # no. 19, 20
  eval { $f = locate($test_mod) };
  like( $@, qr/invalid \@INC/, 'b0rken arrayref return in INC');
  ok( !defined($f), "\$f is not a filehandle");
}

{
  $INC[0] = bless [], 'MLtest::object';
  
  my $f;

  # no. 21, 22
  ok( $f = locate($test_mod), 'IO::File object INC');
  ok( Module::Locate::acts_like_fh($f), "$f is deigned to be a filehandle");

  close $f;
  $INC[0] = bless [], 'MLtest::b0rkobj';
  undef $f;

  # no. 23, 24
  eval { $f = locate($test_mod) };
  like( $@, qr/invalid \@INC/, 'b0rken arrayref return in INC');
  ok( !defined($f), "\$f is not a filehandle");
}

{
  package MLtest::iohandle;

  use base 'IO::Handle';

  package MLtest::overloaded;

  use overload (
    '<>'     => sub { },
    fallback => 1,
  );

  package MLtest::object;

  sub MLtest::object::INC { IO::File->new($test_fn) }

  package MLtest::b0rkobj;

  sub MLtest::b0rkobj::INC { 'wah wah waaaah' }
  
  package MLtest::nought;
}
