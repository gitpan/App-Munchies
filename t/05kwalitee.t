# @(#)$Id: 05kwalitee.t 685 2009-04-23 00:25:10Z pjf $

use strict;
use warnings;
use File::Spec::Functions;
use English  qw( -no_match_vars );
use FindBin  qw( $Bin );
use lib (catdir( $Bin, updir, q(lib) ));
use Test::More;

use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 685 $ =~ /\d+/gmx );

if (!-e catfile( $Bin, updir, q(MANIFEST.SKIP) )) {
   plan skip_all => 'Kwalitee test only for developers';
}

eval { require Test::Kwalitee; };

plan skip_all => 'Test::Kwalitee not installed' if ($EVAL_ERROR);

Test::Kwalitee->import();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
