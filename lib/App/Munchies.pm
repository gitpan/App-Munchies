# @(#)$Id: Munchies.pm 786 2009-06-29 17:28:03Z pjf $

package App::Munchies;

use 5.008;
use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 786 $ =~ /\d+/gmx );

use File::Spec;
use Catalyst::Runtime q(5.70);
use Catalyst qw(ConfigComponents InflateMore ConfigLoader
                Log::Handler Authentication Captcha FillInForm Session
                Session::State::Cookie Session::Store::FastMmap
                Static::Simple);

# Work around C::Utils::home. Stop home directory from changing
my $class = __PACKAGE__;
my $home  = $class->config->{home};
my $dir   = File::Spec->catfile( split m{ :: }mx, $class );
my $file  = Catalyst::Utils::appprefix( $class );

$home = File::Spec->catdir( $home, q(lib), $dir ) if ($home !~ m{ $dir \z }mx);

# Configure application
$class->config
   ( action_class               => q(CatalystX::Usul::Action),
     content_map                => {
        'application/json'         => q(JSON),
        'application/x-storable'   => q(Serializer),
        'application/x-freezethaw' => q(Serializer),
        'application/xhtml+xml'    => q(HTML),
        'application/xml'          => q(HTML),
        'text/html'                => q(HTML),
        'text/x-config-general'    => q(Serializer),
        'text/x-data-dumper'       => q(Serializer),
        'text/x-json'              => q(JSON),
        'text/x-php-serialization' => q(Serializer),
        'text/xml'                 => q(XML) },
     home                       => $home,
     name                       => $class,
     version                    => $VERSION,
     captcha                    => {
        create                  => [ q(ttf), q(ec) ],
        new                     => {
           font                 => q(StayPuft.ttf),
           frame                => 1,
           height               => 90,
           lines                => 10,
           ptsize               => 24,
           scramble             => 1,
           width                => 340, },
        out                     => { force => q(jpeg) },
        particle                => [ 900, 5 ],
        session_name            => q(captcha_string), },
     session                    => {
        expires                 => 7776000,
        storage                 => q(__appldir(var/tmp/session_data)__),
        verify_address          => 1, },
     setup_components           => { except => qr(:: \. \#)mx },
     static                     => {
        dirs                    =>
           [ q(static), qr/^(css|html|images|jscript|reports|skins|svg)/ ],
        ignore_extensions       => [ q(tmpl), q(tt), q(tt2) ],
        include_path            => [ q(__appldir(var/root)__), q(.) ],
        mime_types              => { svg => q(image/svg+xml) }, },
     'Controller::Admin'        => {
        actions                 => { base => { PathPart => q(admin) } },
        namespace               => q(admin), },
     'Controller::Entrance'     => {
        actions                 => { base => { PathPart => q(entrance) } },
        namespace               => q(entrance), },
     'Controller::Library'      => {
        actions                 => { base => { PathPart => q(library) } },
        namespace               => q(library), },
     'Controller::Root'         => {
        parent_classes          => q(CatalystX::Usul::Controller::Root),
        namespace               => q() },
     'Debug'                    => {
        skip_dump_parameters    =>
           q(p_word[12] | password | passwd | newPass[12] | oldPass) },
     'Log::Handler'             => {
        filename                => q(__appldir(var/logs/server.log)__),
        fileopen                => 1,
        mode                    => q(trunc),
        newline                 => 1,
        permissions             => q(0660), },
     'Model::Base'              => {
        parent_classes          => q(CatalystX::Usul::Model) },
     'Model::Config'            => {
        parent_classes          => q(CatalystX::Usul::Model::Config) },
     'Model::Config::Buttons'   => {
        parent_classes          =>
           q(CatalystX::Usul::Model::Config::Buttons) },
     'Model::Config::Credentials' => {
        parent_classes          =>
           q(CatalystX::Usul::Model::Config::Credentials) },
     'Model::Config::Fields'    => {
        parent_classes          => q(CatalystX::Usul::Model::Config::Fields) },
     'Model::Config::Globals'   => {
        parent_classes          =>
           q(CatalystX::Usul::Model::Config::Globals) },
     'Model::Config::Keys'      => {
        parent_classes          => q(CatalystX::Usul::Model::Config::Keys) },
     'Model::Config::Levels'    => {
        parent_classes          => q(CatalystX::Usul::Model::Config::Levels) },
     'Model::Config::Messages'  => {
        parent_classes          =>
           q(CatalystX::Usul::Model::Config::Messages) },
     'Model::Config::Pages'     => {
        parent_classes          => q(CatalystX::Usul::Model::Config::Pages) },
     'Model::Config::Rooms'     => {
        parent_classes          => q(CatalystX::Usul::Model::Config::Rooms) },
     'Model::FileSystem'        => {
        parent_classes          => q(CatalystX::Usul::Model::FileSystem) },
     'Model::Help'              => {
        parent_classes          => q(CatalystX::Usul::Model::Help) },
     'Model::IdentityDBIC'      => {
        parent_classes          => q(CatalystX::Usul::Model::Identity),
        auth_comp               => q(Plugin::Authentication),
        role_class              => q(RolesDBIC),
        user_class              => q(UsersDBIC), },
     'Model::IdentityUnix'      => {
        parent_classes          => q(CatalystX::Usul::Model::Identity),
        auth_comp               => q(Plugin::Authentication),
        role_class              => q(RolesUnix),
        user_class              => q(UsersUnix), },
     'Model::Imager'            => {
        parent_classes          => q(CatalystX::Usul::Model::Imager),
        scale                   => { scalefactor => 0.5 } },
     'Model::MailAliases'       => {
        parent_classes          => q(CatalystX::Usul::Model::MailAliases) },
     'Model::MealMaster'        => {
        COMPILE_DIR             => q(__appldir(var/tmp)__),
        INCLUDE_PATH            => q(__appldir(var/root/static/templates)__) },
     'Model::Navigation'        => {
        parent_classes          => q(CatalystX::Usul::Model::Navigation) },
     'Model::Process'           => {
        parent_classes          => q(CatalystX::Usul::Model::Process) },
     'Model::RolesDBIC'         => {
        parent_classes          => q(CatalystX::Usul::Model::Roles),
        domain_attributes       => {
           dbic_role_class      => q(Authentication::Roles),
           dbic_user_roles_class => q(Authentication::UserRoles), },
        domain_class            => q(CatalystX::Usul::Roles::DBIC) },
     'Model::RolesUnix'         => {
        parent_classes          => q(CatalystX::Usul::Model::Roles),
        domain_class            => q(CatalystX::Usul::Roles::Unix) },
     'Model::Session'           => {
        parent_classes          => q(CatalystX::Usul::Model::Session) },
     'Model::Tapes'             => {
        parent_classes          => q(CatalystX::Usul::Model::Tapes) },
     'Model::UserProfiles'      => {
        parent_classes          => q(CatalystX::Usul::Model::UserProfiles) },
     'Model::UsersDBIC'         => {
        parent_classes          => q(CatalystX::Usul::Model::Users),
        COMPILE_DIR             => q(__appldir(var/tmp)__),
        INCLUDE_PATH            => q(__appldir(var/root/static/templates)__),
        domain_attributes       => {
           dbic_user_class      => q(Authentication::Users), },
        domain_class            => q(CatalystX::Usul::Users::DBIC) },
     'Model::UsersUnix'         => {
        parent_classes          => q(CatalystX::Usul::Model::Users),
        COMPILE_DIR             => q(__appldir(var/tmp)__),
        INCLUDE_PATH            => q(__appldir(var/root/static/templates)__),
        domain_attributes       => {
           common_home          => q(/home/common), },
        domain_class            => q(CatalystX::Usul::Users::Unix) },
     'Plugin::Authentication'   => {
        default_realm           => q(R01-Localhost),
        realms                  => {
           'R01-Localhost'      => {
              credential        => {
                 class          => q(Password),
                 password_field => q(password),
                 password_type  => q(self_check), },
              store             => {
                 class          => q(+CatalystX::Usul::Authentication),
                 model_class    => q(IdentityUnix),
                 user_field     => q(username), }, },
           'R02-Database'       => {
              credential        => {
                 class          => q(Password),
                 password_field => q(password),
                 password_type  => q(self_check), },
              store             => {
                 class          => q(+CatalystX::Usul::Authentication),
                 model_class    => q(IdentityDBIC),
                 user_field     => q(username), }, }, }, },
     'Plugin::ConfigLoader'     => {
        file                    => File::Spec->catfile( $home, $file ) },
     'Plugin::InflateMore'      => q(CatalystX::Usul::InflateSymbols),
     'View::HTML'               => {
        parent_classes          => q(CatalystX::Usul::View::HTML),
        COMPILE_DIR             => q(__appldir(var/tmp)__),
        INCLUDE_PATH            => q(__appldir(var/root/skins)__),
        dynamic_templates       => q(__appldir(var/root/dynamic/templates)__),
        jscript_dir             => q(__appldir(var/root/static/jscript)__),
        lang_dep_jsprefixs      => [ qw(calendar) ], },
     'View::JSON'               => {
        parent_classes          => q(CatalystX::Usul::View::JSON),
        dynamic_templates       =>
           q(__appldir(var/root/dynamic/templates)__), },
     'View::Serializer'         => {
        parent_classes          => q(CatalystX::Usul::View::Serializer), },
     'View::XML'                => {
        parent_classes          => q(CatalystX::Usul::View::XML),
        dynamic_templates       =>
           q(__appldir(var/root/dynamic/templates)__), },
     );

# Initialise application
$class->setup;

# TODO: Temporarily put the no strict no warnings in Class:Data::Inheritable
# to suppress the config redefined warnings
Class::C3::initialize();

# Methods in the Catalyst objects namespace

sub list_sessions {
   # TODO: Move this method to the C::P::Session::Store::FastMmap
   return shift->_session_fastmmap_storage->get_keys( 2 );
}

1;

__END__

=pod

=head1 Name

App::Munchies - Catalyst example application using food recipes as a data set

=head1 Version

0.3.$Revision: 786 $

=head1 Synopsis

Start the development mini server with

   bin/munchies_server.pl

=head1 Description

This is an example application for the L<CatalystX::Usul> base classes

Some web applications require common controllers and data
models. For example; welcome mat, authentication, password changing,
navigation tools and site map are some of the controllers implemented
here. Since these modules are not an end in themselves, most of the
visible text is stored in XML configuration files and can be
customised using the controllers and data models provided. The string
"Munchies" for example is a generic application name and it is meant
to be replaced with a more specific application name once it has been
written

Pages are rendered using a single TT template. The template, CSS,
Javascript and collection of GIFs, PNG, etc are stored together and
form a "skin" for which a switching mechanism is provided. This
enables development of the web application to proceed independently of
the interface development. Content (provided by Perl on Catalyst) has
been separated from layout (TT+CSS), presentation (CSS) and behaviour
(JS). If the interface is not to your liking, write your own
skin. These ideas and techniques have been aquired from
L<http://www.csszengarden.com/> and L<http://www.cssplay.co.uk/>

Don't even think about using anything other than a modern version of
Firefox to display these pages

=head1 Installation

Run these commands as root to install this application from a
distribution tarball:

   tar -xvzf App-Munchies-?.?.?.tar.gz
   cd App-Munchies-?.?.?
   ./install.sh

It defaults to installing all files (including the F<var> data) under
F</opt/app-munchies> (which is easy to remove if this is not a
permanent installation)

If you want to customise the installation then instead of
C<install.sh> run

   ./Build.PL
   ./Build --ask
   ./Build distclean
   cd ..
   tar -czf App-Munchies-local.tar.gz App-Munchies-?.?.?

which will create a local tarball. Install from this and you will not
be prompted to answer any more questions

Once the schema has been deployed and populated the following
(optional) commands will be run:

   bin/munchies_cli    -n -c pod2html    -o uid=[% uid %] -o gid=[% gid %]
   bin/munchies_schema -n -c catalog_mmf -o uid=[% uid %] -o gid=[% gid %]

as the I<munchies> user. They may take some time to finish. When
complete the F<var> area of the application is about 60Mb in size

This distribution contains a setuid root program. It is used to
provide limited access to root only functions, e.g. authentication
against F</etc/shadow>. The build process asks if this should be
enabled.  It is not enabled by default

B<N.B.> Remove I<user_root> from F<var/secure/support.sub> if it exists

B<N.B.> Change the password for the admin account in the R02-Database realm

=head1 Subroutines/Methods

=head2 list_sessions

Lists the users session data stored in
L<Catalyst::Plugin::Session::Store::FastMmap>

This method should be implemented on each of the C::P::S::Store::* backends

=head1 Diagnostics

Append C<-d> to F<bin/munchies_server.pl> to start the mini server in
debug mode

Replace the prepare body method in I<Catalyst.pm> with this one

   sub prepare_body {
      my $c = shift;

      # Do we run for the first time?
      return if defined $c->request->{_body};

      # Initialize on-demand data
      $c->engine->prepare_body( $c, @_ );
      $c->prepare_parameters;
      $c->prepare_uploads;

      if ( $c->debug && keys %{ $c->req->body_parameters } ) {
         my $params = $c->req->body_parameters;
         my $re = $c->config->{Debug}->{skip_dump_parameters};
         my $t = Text::SimpleTable->new( [ 35, 'Parameter' ], [ 36, 'Value' ] );

         for my $key ( sort keys %{ $params } ) {
            my $param = exists $params->{ $key } ? $params->{ $key } : q();
            my $value = ref $param eq q(ARRAY)
                      ? (join q(, ), @{ $param }) : $param;

            $value = q(*) x length $value if ($re && $key =~ m{ \A $re \z }mx);

            $t->row( $key, $value );
         }

         $c->log->debug( "Body Parameters are:\n" . $t->draw );
      }
   }

=head1 Configuration and Environment

Application configuration is in the file
F<lib/app_munchies/app_munchies.xml>

=head1 Dependencies

=over 3

=item L<Catalyst>

=item L<Catalyst::Plugin::ConfigComponents>

=item L<Catalyst::Plugin::InflateMore>

=item L<CatalystX::Usul>

=back

=head1 Incompatibilities

Cygwin - Has a wierd gecos field in the passwd file that is a problem
for the identity model.

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 License and Copyright

Copyright (c) 2009 Peter Flanigan. All rights reserved

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
