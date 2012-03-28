# @(#)$Id: 02pod.t 1187 2011-06-04 03:19:20Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1187 $ =~ /\d+/gmx );
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
