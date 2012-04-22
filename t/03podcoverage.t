# @(#)$Id: 03podcoverage.t 1318 2012-04-22 17:10:47Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use English qw( -no_match_vars );
use Test::More;

BEGIN {
   if (!-e catfile( $Bin, updir, q(MANIFEST.SKIP) )) {
      plan skip_all => 'POD coverage test only for developers';
   }
}

eval { use Test::Pod::Coverage 1.04; };

$EVAL_ERROR and plan skip_all => 'Test::Pod::Coverage 1.04 required';

$ENV{BUILDING_DEBIAN} and plan skip_all => 'POD coverage building debian';

all_pod_coverage_ok();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
