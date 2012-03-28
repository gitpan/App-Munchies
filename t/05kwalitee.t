# @(#)$Id: 05kwalitee.t 1187 2011-06-04 03:19:20Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1187 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use English qw( -no_match_vars );
use Test::More;

if (!-e catfile( $Bin, updir, q(MANIFEST.SKIP) )) {
   plan skip_all => 'Kwalitee test only for developers';
}

eval { require Test::Kwalitee; };

$EVAL_ERROR and plan skip_all => 'Test::Kwalitee not installed';

$ENV{BUILDING_DEBIAN} and plan skip_all => 'Test::Kwalitee building debian';

my $tests = [ qw(extractable has_readme has_manifest has_meta_yml
                 has_buildtool has_changelog no_symlinks has_tests
                 proper_libs use_strict has_test_pod
                 has_test_pod_coverage) ];

not -d q(local) and push @{ $tests }, q(no_pod_errors);

Test::Kwalitee->import( tests => $tests );

# Local Variables:
# mode: perl
# tab-width: 3
# End:
