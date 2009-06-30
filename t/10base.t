# @(#)$Id: 10base.t 287 2008-11-22 14:45:33Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.4.%d', q$Rev: 108 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use English qw( -no_match_vars );
use Test::More;

BEGIN {
   if ($ENV{AUTOMATED_TESTING}  || $ENV{PERL_CR_SMOKER_CURRENT} ||
       $ENV{PERL5_MINISMOKEBOX} || $ENV{PERL5_YACSMOKE_BASE}) {
      plan skip_all => q(CPAN Testing stopped);
   }

   plan tests => 3;
}

my $dir = catdir( q(var), q(logs) ); mkdir $dir unless (-e $dir);

$dir = catdir( q(var), q(tmp) ); mkdir $dir unless (-e $dir);

use_ok q(Catalyst::Test), q(App::Munchies);

ok( request( q(http://localhost:3000/en/entrance/reception) )->is_success,
    q(Request for entrance/reception failed) );

like( get( q(http://localhost:3000/en/entrance/reception) ),
      qr{ entrance#reception }mx,
      q(Response for entrance/reception did not contain string reception_view) );

# Local Variables:
# mode: perl
# tab-width: 3
# End:
