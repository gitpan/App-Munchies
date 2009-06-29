# @(#)$Id: Makefile.PL 773 2009-06-20 23:26:56Z pjf $

use strict;
use warnings;

sub _error { my $text = shift; print {*STDOUT} $text."\n"; exit 0 }

system "$^X Build.PL"; _error 'No Build file' unless (-f 'Build');

my $makefile = <<'EOT';
default:
	./Build

test:
	./Build test

install:
	./Build install

installdeps:
	./Build installdeps
EOT

open  MF, '>', 'Makefile' or _error 'Cannot write Makefile';
print MF $makefile;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
