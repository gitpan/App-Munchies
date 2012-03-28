# @(#)$Id: CPANTesting.pm 1287 2012-03-28 11:06:38Z pjf $

package CPANTesting;

use strict;
use warnings;

my $uname = qx(uname -a);

sub broken {
   $uname     =~ m{ bandsman      }mx and return 'Stopped Horne';
   $uname     =~ m{ higgsboson    }mx and return 'Stopped dcollins';
   $uname     =~ m{ profvince.com }mx and return 'Stopped vpit';
   $ENV{PATH} =~ m{ \A /home/sand }mx and return 'Stopped Konig';
   return 0;
}

1;

__END__
