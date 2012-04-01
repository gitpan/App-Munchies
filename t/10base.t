# @(#)$Id: 10base.t 287 2008-11-22 14:45:33Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 108 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use English qw( -no_match_vars );
use Module::Build;
use Test::More;

BEGIN {
   my $current = eval { Module::Build->current };

   $current and $current->notes->{stop_tests}
            and plan skip_all => $current->notes->{stop_tests};

   plan tests => 3;
}

my $dir = catdir( q(var), q(logs) ); mkdir $dir unless (-e $dir);

$dir = catdir( q(var), q(tmp) ); mkdir $dir unless (-e $dir);

use_ok q(Catalyst::Test), q(App::Munchies);

ok( request( q(/entrance/reception) )->is_success,
    q(Request for entrance/reception) );

like( get( q(/entrance/reception) ),
      qr{ entrance#reception }mx,
      q(Response for entrance/reception did not contain known string) );

# Local Variables:
# mode: perl
# tab-width: 3
# End:
