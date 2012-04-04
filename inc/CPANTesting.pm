# @(#)$Id: CPANTesting.pm 1305 2012-04-04 18:31:41Z pjf $

package CPANTesting;

use strict;
use warnings;

my $uname = qx(uname -a);

sub broken_toolchain {
   $ENV{PATH} =~ m{ \A /home/sand         }mx and return 'Stopped Konig';
   $ENV{PATH} =~ m{ \A /usr/home/cpan/pit }mx and return 'Stopped Bingos';
   $uname     =~ m{ higgsboson            }mx and return 'Stopped dcollins';
   return 0;
}

sub exceptions {
   $uname =~ m{ slack64 }mx and return 'Stopped Bingos slack64';
   return 0;
}

1;

__END__
