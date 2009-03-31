package App::Munchies::Programs::Suid;

# @(#)$Id: Suid.pm 51 2008-04-04 01:23:54Z pjf $

use strict;
use warnings;
use base qw(CatalystX::Usul::Programs);
use CatalystX::Usul::Model::Identity;
use Class::C3;
use IO::Interactive qw(is_interactive);

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 51 $ =~ /\d+/gmx );

__PACKAGE__->mk_accessors( qw(identity parms secsdir version) );

sub new {
   my ($class, @rest) = @_;
   my $self     = $class->next::method( $class->arg_list( @rest ) );
   my $config   = { role_class => q(Roles::Unix), user_class => q(Suid) };
   my $id_class = q(CatalystX::Usul::Model::Identity);

   $self->{identity} = $id_class->new( $self, $config );
   $self->{parms   } = { update_password => [ 0 ] };
   $self->{secsdir } = $self->catdir( $self->vardir, 'secure' );
   $self->{version } = $VERSION;
   return $self;
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
                    { arg1 => $e->arg1, arg2 => $e->arg2 } );
      return 1;
   }

   return 0;
}

sub authorise {
   my ($self, $ref) = @_; my ($method, $path, $role, $roles, $user);

   $method = $ref->{method}; $user = $ref->{user};

   return 1 if ($method eq q(authenticate) || $method eq q(change_password));

   for $role ($self->roles->get_roles( $user )) {
      $path = $self->catfile( $self->secsdir, $role.q(.sub) );

      next unless (-f $path);

      for ($self->io( $path )->chomp->getlines) {
         next unless ($_ eq $method);

         return 1 unless (m{ \A user_ }msx);

         s{ \A user_ }{}msx;
         $self->parms->{set_user} = [ $_ ];
         $self->method( q(set_user) );
         return 1;
      }
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

sub roles {
   my $self = shift; return $self->identity->roles;
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
   my ($self, $user) = @_; my ($cmd, @lines, $logger, $logname, $path, $res);

   $self->throw( q(eNotInteractive) ) unless (is_interactive());

   unless ($logger = $self->os->{logger}->{value}) {
      $self->throw( q(eNoLogger) );
   }

   unless (-x $logger) {
      $self->throw( error => q(eCannotExecute), arg1 => $logger );
   }

   $logname = $self->logname;

   if ($logname =~ m{ \A ([\w.]+) \z }msx) { $logname = $1 }

   $cmd  = $logger.' -t suid -p auth.info -i "su ';
   $cmd .= $logname.q(-).$user.'" ';
   $self->run_cmd( $cmd );
   $path = $self->catfile( $self->binsdir, $self->prefix.'_suenv' );

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

   exec $cmd or _croak();
   return;
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
   $cmd  = $self->catfile( $self->binsdir, $self->prefix.'_misc' );
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

sub users {
   my $self = shift; return $self->identity->users;
}

# Private methods

sub _croak {
   require Carp; goto &Carp::croak;
}

1;

__END__

=pod

=head1 Name

<Module::Name> - <One-line description of module's purpose>

=head1 Version

0.1.$Revision$

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 new

=head2 account_report

=head2 aliases_update

=head2 authenticate

=head2 authorise

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

=item L<Class::Accessor::Fast>

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
