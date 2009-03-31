# @(#)$Id: 02pod.t 546 2008-11-22 22:23:20Z pjf $

use strict;
use warnings;
use Test::More;

eval { use Test::Pod 1.14; };

plan skip_all => 'Test::Pod 1.14 required' if ($@);

all_pod_files_ok();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
