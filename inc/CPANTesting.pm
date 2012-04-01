# @(#)$Id: CPANTesting.pm 1292 2012-04-01 23:13:06Z pjf $

package CPANTesting;

use strict;
use warnings;

my $uname = qx(uname -a);

sub broken_toolchain {
#   $ENV{PATH} =~ m{ \A /home/sand }mx and return 'Stopped Konig';
#   $uname     =~ m{ bandsman      }mx and return 'Stopped Horne';
#   $uname     =~ m{ fremen        }mx and return 'Stopped Bingos';
#   $uname     =~ m{ nexus         }mx and return 'Stopped Bingos';
#   $uname     =~ m{ oatcake       }mx and return 'Stopped Bingos';
#   $uname     =~ m{ oliphant      }mx and return 'Stopped Bingos';
   $uname     =~ m{ slack64       }mx and return 'Stopped Bingos';
   return 0;
}

sub exceptions {
#   $uname =~ m{ higgsboson    }mx and return 'Stopped dcollins';
#   $uname =~ m{ profvince.com }mx and return 'Stopped vpit';
   return 0;
}

1;

__END__
