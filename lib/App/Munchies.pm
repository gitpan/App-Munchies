# @(#)$Id: Munchies.pm 1301 2012-04-04 08:10:52Z pjf $

package App::Munchies;

use 5.010;
use strict;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1301 $ =~ /\d+/gmx );

use Moose;
use File::Spec;
use Catalyst::Runtime q(5.90010);
use CatalystX::RoleApplicator;

use Catalyst qw(ConfigComponents InflateMore ConfigLoader Log::Handler
                Authentication Session Session::State::Cookie
                Session::Store::FastMmap Static::Simple);

# Add a method to list FastMmap sessions
with qw(CatalystX::Usul::TraitFor::ListSessions);
# Suppress printing of passwords in debug output
with qw(CatalystX::Usul::TraitFor::LogRequest);

my $class = __PACKAGE__;
my $home  = $class->config->{home};
my $file  = Catalyst::Utils::appprefix( $class );
my $dir   = File::Spec->catdir( split m{ :: }mx, $class );

# Work around C::Utils::home. Stop home directory from changing
$home !~ m{ $dir \z }mx and $home = File::Spec->catdir( $home, q(lib), $dir );

# Prefer Data::Dumper for debug information
$class->apply_engine_class_roles
   ( qw(CatalystX::Usul::TraitFor::Engine::DumpInfo) );

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
        'text/x-xml'               => q(XML),
        'text/xml'                 => q(XML) },
     home                       => $home,
     name                       => $class,
     version                    => $VERSION,
     static                     => {
        dirs                    => [ qr/^(html|reports|skins|static)/ ],
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
        actions                 => { base => { PathPart => q(library) } }, },
     'Controller::Library::Admin' => {
        actions                 => { base => { PathPart => q(library) } },
        namespace               => q(library) },
     'Controller::Library::Catalog' => {
        actions                 => { base => { PathPart => q(library) } },
        namespace               => q(library), },
     'Controller::Library::Recipes' => {
        actions                 => { base => { PathPart => q(library) } },
        namespace               => q(library), },
     'Controller::Root'         => {
        parent_classes          => q(CatalystX::Usul::Controller::Root),
        default_namespace       => q(entrance),
        namespace               => q() },
     'Debug'                    => {
        skip_dump_elements      => q(__InstancePerContext | nav_model | _log),
        skip_dump_parameters    =>
     q(p_word[12] | password | password[12] | passwd | newPass[12] | oldPass) },
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
     'Model::IdentitySimple'    => {
        parent_classes          => q(CatalystX::Usul::Model::Identity),
        auth_comp               => q(Plugin::Authentication),
        role_class              => q(RolesSimple),
        user_class              => q(UsersSimple), },
     'Model::IdentityUnix'      => {
        parent_classes          => q(CatalystX::Usul::Model::Identity),
        auth_comp               => q(Plugin::Authentication),
        role_class              => q(RolesUnix),
        user_class              => q(UsersUnix), },
     'Model::Imager'            => {
        parent_classes          => q(CatalystX::Usul::Model::Imager),
        scale                   => { scalefactor => 0.5 } },
     'Model::MailAliases'       => {
        parent_classes          => q(CatalystX::Usul::Model::MailAliases),
        domain_attributes       => {
           root_update_cmd      => q(__binsdir(munchies_admin)__), }, },
     'Model::MealMaster'        => {
        template_dir            => q(__appldir(var/root/templates)__) },
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
     'Model::RolesSimple'       => {
        parent_classes          => q(CatalystX::Usul::Model::Roles),
        domain_class            => q(CatalystX::Usul::Roles::Simple) },
     'Model::RolesUnix'         => {
        parent_classes          => q(CatalystX::Usul::Model::Roles),
        domain_class            => q(CatalystX::Usul::Roles::Unix) },
     'Model::Session'           => {
        parent_classes          => q(CatalystX::Usul::Model::Session) },
     'Model::TapeBackup'        => {
        parent_classes          => q(CatalystX::Usul::Model::TapeBackup) },
     'Model::Templates'         => {
        parent_classes          => q(CatalystX::Usul::Model::Templates), },
     'Model::UserProfiles'      => {
        parent_classes          => q(CatalystX::Usul::Model::UserProfiles), },
     'Model::UsersDBIC'         => {
        parent_classes          => q(CatalystX::Usul::Model::Users),
        domain_attributes       => {
           dbic_user_class      => q(Authentication::Users), },
        domain_class            => q(CatalystX::Usul::Users::DBIC),
        template_attributes     => {
           COMPILE_DIR          => q(__appldir(var/tmp)__),
           INCLUDE_PATH         => q(__appldir(var/root/templates)__), }, },
     'Model::UsersSimple'       => {
        parent_classes          => q(CatalystX::Usul::Model::Users),
        domain_class            => q(CatalystX::Usul::Users::Simple) },
     'Model::UsersUnix'         => {
        parent_classes          => q(CatalystX::Usul::Model::Users),
        domain_attributes       => {
           common_home          => q(/home/common), },
        domain_class            => q(CatalystX::Usul::Users::Unix),
        template_attributes     => {
           COMPILE_DIR          => q(__appldir(var/tmp)__),
           INCLUDE_PATH         => q(__appldir(var/root/templates)__), }, },
     'Plugin::Authentication'   => {
        default_realm           => q(R00-Internal),
        realms                  => {
           'R00-Internal'       => {
              credential        => {
                 class          => q(Password),
                 password_field => q(password),
                 password_type  => q(self_check), },
              store             => {
                 class          => q(+CatalystX::Usul::Authentication),
                 model_class    => q(IdentitySimple),
                 user_field     => q(username), }, },
           'R01-Database'       => {
              credential        => {
                 class          => q(Password),
                 password_field => q(password),
                 password_type  => q(self_check), },
              store             => {
                 class          => q(+CatalystX::Usul::Authentication),
                 model_class    => q(IdentityDBIC),
                 user_field     => q(username), }, }, }, },
     'Plugin::Captcha'          => {
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
     'Plugin::ConfigLoader'     => {
        file                    => File::Spec->catfile( $home, $file ) },
     'Plugin::InflateMore'      => q(CatalystX::Usul::InflateSymbols),
     'Plugin::Session'          => {
        cookie_httponly         => 0,
        expires                 => 7776000,
        storage                 => q(__appldir(var/tmp/session_data)__),
        verify_address          => 1, },
     'View::HTML'               => {
        parent_classes          => q(CatalystX::Usul::View::HTML),
        COMPILE_DIR             => q(__appldir(var/tmp)__),
        INCLUDE_PATH            => q(__appldir(var/root/skins)__),
        jscript_dir             => q(__appldir(var/root/static/jscript)__),
        lang_dep_jsprefixs      => [ qw(calendar) ],
        render_die              => 0,
        template_dir            => q(__appldir(var/root/templates)__), },
     'View::JSON'               => {
        parent_classes          => q(CatalystX::Usul::View::JSON), },
     'View::Serializer'         => {
        parent_classes          => q(CatalystX::Usul::View::Serializer), },
     'View::XML'                => {
        parent_classes          => q(CatalystX::Usul::View::XML),
        template_dir            => q(__appldir(var/root/templates)__), },
     );

# Initialise application
$class->setup;

no Moose;

1;

__END__

=pod

=head1 Name

App::Munchies - Catalyst example application using food recipes as a data set

=head1 Version

0.6.$Revision: 1301 $

=head1 Synopsis

   # Start the development server with

   bin/munchies_server -d -r -rd 1 -rr "\\.xml\$|\\.pm\$" \
      --restart_directory lib

   # Start the production server with

   plackup -s Starman --access-log var/logs/starman_server.log \
      bin/munchies_psgi

=head1 Description

This is an example application for the L<CatalystX::Usul> base class

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
Chrome / Firefox / Opera to display these pages

=head1 Dependencies

Either Apache/mod_perl or Plack/Starman is required to serve HTTP (the
other Catalyst engines are also supported). Requires either PostgreSQL
or MySQL to be installed. The XML parser requires C<libxml2> and
C<libxml2-dev> otherwise a slow pure Perl implementation will be
used. Installing Perl module dependencies from CPAN will require
C<make>, C<gcc> and C<g++> (or equivalents) to be
installed. L<GD::SecurityImage> (used to generate Captchas) depends on
C<libgd2-noxpm> and C<libgd2-noxpm-dev>. It also requires the
C<StayPuft.ttf> font to be installed

=head1 Installation

Run these commands as root to install this application from a
distribution tarball:

   tar -xvzf App-Munchies-?.?.?.tar.gz
   cd App-Munchies-?.?.?
   ./install.sh

It defaults to installing all files (including the F<var> data) under
F</opt/app-munchies> (which is easy to remove if this is not a
permanent installation)

Once the schema has been deployed and populated the following
(optional) commands will be run:

   bin/munchies_cli    -nc pod2html
   bin/munchies_schema -nc catalog_mmf

as the I<munchies> user. They may take some time to finish. When
complete the F<var> area of the application is about 60Mb in size

This distribution contains a setuid root program. It is used to
provide limited access to root only functions, e.g. authentication
against F</etc/shadow>. The build process asks if this should be
enabled.  It is not enabled by default

B<N.B.> Remove I<user_root> from F<var/secure/support.sub> if it exists

B<N.B.> Change the password for the admin account in the R00-Internal realm

=head1 Configuration and Environment

Application configuration is in the file
F<lib/App/Munchies/app_munchies.xml>

=head1 Diagnostics

The C<-d> option on the F<bin/munchies_server.pl> command line starts the
development server server in debug mode

=head1 Subroutines/Methods

None

=head1 Incompatibilities

Cygwin - Has a wierd gecos field in the passwd file that is a problem
for the identity model.

The L<Pod::ProjectDocs> module will not install without
forcing. L<CatalystX::Usul::ProjectDocs> monkey patches
L<Pod::ProjectDocs> with a different syntax highlighter so that the post
install commands can generate the HTML version the application
documentation

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 License and Copyright

Copyright (c) 2012 Peter Flanigan. All rights reserved

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

