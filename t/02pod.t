# @(#)$Id: 02pod.t 1318 2012-04-22 17:10:47Z pjf $

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
      plan skip_all => 'POD test only for developers';
   }
}

eval { use Test::Pod 1.14; };

$EVAL_ERROR and plan skip_all => 'Test::Pod 1.14 required';

$ENV{BUILDING_DEBIAN} and plan skip_all => 'POD test building debian';

all_pod_files_ok();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
