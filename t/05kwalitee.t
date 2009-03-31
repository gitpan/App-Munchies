# @(#)$Id: 05kwalitee.t 546 2008-11-22 22:23:20Z pjf $

use strict;
use warnings;
use File::Spec::Functions;
use FindBin ();
use Test::More;

if (!-e catfile( $FindBin::Bin, updir, q(MANIFEST.SKIP) )) {
   plan skip_all => 'Kwalitee test only for developers';
}

eval { require Test::Kwalitee; };

plan skip_all => 'Test::Kwalitee not installed' if ($@);

Test::Kwalitee->import();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
