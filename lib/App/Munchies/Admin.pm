# @(#)$Id: Admin.pm 783 2009-06-27 11:20:50Z pjf $

package App::Munchies::Admin;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 783 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Programs);

use CatalystX::Usul::Roles::Unix;
use CatalystX::Usul::Users::Suid;
use Class::C3;
use English         qw(-no_match_vars);
use IO::Interactive qw(is_interactive);

__PACKAGE__->mk_accessors( qw(parms roles secsdir users version) );

sub new {
   my ($self, @rest) = @_;

   my $new = $self->next::method( $self->arg_list( @rest ) );

   $new->parms  ( { update_password => [ 0 ] }                  );
   $new->roles  ( CatalystX::Usul::Roles::Unix->new( $new, {} ) );
   $new->secsdir( $new->catdir( $new->vardir, 'secure' )        );
   $new->users  ( CatalystX::Usul::Users::Suid->new( $new, {} ) );
   $new->version( $VERSION                                      );

   return $new;
}

sub is_authorised {
   my $self = shift; my $method = $self->method; my $user = $self->logname;

   return 0 unless ($method and $user);

   return 1 if ($method eq q(authenticate) or $method eq q(change_password));

   for my $role ($self->roles->get_roles( $user )) {
      my $path = $self->catfile( $self->secsdir, $role.q(.sub) );

      next unless (-f $path);

      for my $line ($self->io( $path )->chomp->getlines) {
         next unless ($line eq $method);

         return 1 unless (q(user_) eq substr $line, 0, 5);

         $self->parms->{set_user} = [ substr $line, 5 ];
         $self->method( q(set_user) );
         return 1;
      }
   }

   return 0;
}

sub account_report {
   my $self = shift;

   $self->info( $self->users->user_report( @ARGV ), { no_lead => 1 } );
   return 0;
}

sub aliases_update {
   my $self = shift;

   my $aliases = CatalystX::Usul::MailAliases->new( $self );

   $self->output( $aliases->update_file( @ARGV ) );
   return 0;
}

sub authenticate {
   my $self = shift; my $e;

   eval { $self->users->authenticate( 1, @ARGV ) };

   if ($e = $self->catch) {
      $self->error( $e->as_string( ($self->debug ? 2 : 1), 2 ),
                    { args => $e->args } );
      return 1;
   }

   return 0;
}

sub create_account {
   my $self = shift;

   $self->info( $self->users->create_account( @ARGV ) );
   return 0;
}

sub delete_account {
   my $self = shift;

   $self->info( $self->users->delete_account( @ARGV ) );
   return 0;
}

sub populate_account {
   my $self = shift;

   $self->info( $self->users->populate_account( @ARGV ) );
   return 0;
}

sub roles_update {
   my $self = shift;

   $self->output( $self->roles->roles_update( @ARGV ) );
   return 0;
}

sub set_password {
   return shift->update_password( 1 );
}

sub set_user {
   my ($self, $user) = @_; my $logger;

   $self->throw( 'Not interactive' ) unless (is_interactive());

   unless ($logger = $self->os->{logger}->{value}) {
      $self->throw( 'No logger specified' );
   }

   unless (-x $logger) {
      $self->throw( error => 'Cannot execute [_1]', args => [ $logger ] );
   }

   my $logname = $self->logname;

   if ($logname =~ m{ \A ([\w.]+) \z }msx) { $logname = $1 }

   my $msg = "Admin suid from $logname to $user";
   my $cmd = $logger.' -t suid -p auth.info -i "'.$msg.'" ';

   $self->run_cmd( $cmd );

   my $path = $self->catfile( $self->binsdir, $self->prefix.'_suenv' );

   if ($ARGV[0] && $ARGV[0] eq q(-)) {
      # Old style full login, ENV unset, HOME set for new user
      $cmd = 'su - '.$user;
   }
   elsif ($ARGV[0] && $ARGV[0] eq q(+)) {
      # Keep ENV as now, set HOME for new user
      $cmd = 'su '.$user.' -c ". '.$path.' '.$user.'" ';
   }
   else {
      # HOME from old user,  ENV set from old user
      $cmd = 'su '.$user.' -c "HOME='.$ENV{HOME}.' . '.$path.' '.$user.'" ';
   }

   exec $cmd
      or $self->throw( error => 'Exec failed [_1]', args => [ $ERRNO ] );
   return; # Never reached
}

sub signal_process {
   my $self = shift;

   $self->vars->{pids} = \@ARGV;
   $self->next::method( %{ $self->vars } );
   return 0;
}

sub tape_backup {
   my $self = shift; my ($cmd, $res, $text);

   $self->info( 'Starting tape backup on '.$self->vars->{device} );
   $cmd  = $self->catfile( $self->binsdir, $self->prefix.'_cli' );
   $cmd .= $self->debug ? ' -D' : ' -n';
   $cmd .= ' -c tape_backup -L '.$self->language;

   for (keys %{ $self->vars }) { $cmd .= ' -o '.$_.q(=).$self->vars->{ $_ } }

   $cmd .= ' -- '.(join ' ', @ARGV);

   $self->output( $self->run_cmd( $cmd )->out );
   return 0;
}

sub update_account {
   my $self = shift;

   $self->info( $self->users->update_account( @ARGV ) );
   return 0;
}

sub update_password {
   my $self = shift;

   $self->output( $self->users->update_password( shift, @ARGV ) );
   return 0;
}

sub update_progs {
   my $self = shift; my $cmd;

   $cmd  = 'su '.$self->owner.' -c "scp -i '.$self->ssh_id;
   $cmd .= ' '.$ARGV[0].' '.$ARGV[1].'" ';
   $self->info( $self->run_cmd( $cmd, { err => q(out) } )->out );
   return 0;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Admin - Subroutines that run as the super user

=head1 Version

0.3.$Revision: 783 $

=head1 Synopsis

   use App::Munchies::Admin;
   use English qw(-no_match_vars);

   my $prog = App::Munchies::Admin->new( appclass => q(App::Munchies),
                                         arglist  => q(e) );

   $EFFECTIVE_USER_ID  = 0; $REAL_USER_ID  = 0;
   $EFFECTIVE_GROUP_ID = 0; $REAL_GROUP_ID = 0;

   unless ($prog->is_authorised) {
      my $text = 'Permission denied to '.$prog->method.' for '.$prog->logname;

      $prog->error( $text );
      exit 1;
   }

   exit $prog->dispatch;

=head1 Description

=head1 Subroutines/Methods

=head2 new

=head2 is_authorised

=head2 account_report

=head2 aliases_update

=head2 authenticate

=head2 create_account

=head2 delete_account

=head2 populate_account

=head2 roles

=head2 roles_update

=head2 set_password

=head2 set_user

=head2 signal_process

=head2 tape_backup

=head2 update_account

=head2 update_password

=head2 update_progs

=head2 users

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::Programs>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2008 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
