# ABSTRACT: Create an environment for testing the Act application
use 5.20.0;
package Test::Act::Environment;

use Moo;
use Types::Standard qw(InstanceOf Str);
use namespace::clean;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use File::Temp qw(tempdir);
use File::Copy::Recursive qw(dircopy);

use FindBin qw($RealBin);
FindBin::again();

use Test::WWW::Mechanize::PSGI;

use Test::Lib;
use Test::Act::SMTP::Server;

my $tempdir;

# This needs to happen _before_ Act::Config is used...
BEGIN {
    $tempdir = File::Temp->newdir( CLEANUP => 0 );
    # The following will need adaption to the post-november master
    # Part 1: Link the distribution files from the repository so that
    # changes in the working tree become immediately effective
    for my $dir (qw(templates po wwwdocs)) {
        symlink "$RealBin/../$dir","$tempdir/$dir"
            or die "Failed to create a symlink for '$RealBin/../$dir': '$!'";
    }
    # Part 2: Copy the files from the test environment
    for my $dir (qw(actdocs conf conferences)) {
        dircopy "$RealBin/acthome/$dir","$tempdir/$dir";
    }
    # Part 3: These must just exist
    for my $dir (qw(photos ttc)) {
        mkdir "$tempdir/$dir" or die "Could not create '$tempdir/$dir': '$!'";
    }
    $ENV{ACTHOME} = "$tempdir";
}

use Act::Config;

my $smtp_server = Test::Act::SMTP::Server->instance;
$Config->set(email_hostname => 'localhost');
$Config->set(email_port     => $smtp_server->port);


has mech => (
    is => 'rwp', isa => InstanceOf['Test::WWW::Mechanize'],
    builder => 'build_mech',
    documentation =>
        'A test client for the application tests',
);

sub build_mech ($self) {
    require Act::Dispatcher;
    my $mech = Test::WWW::Mechanize::PSGI->new(app => Act::Dispatcher->to_app);
    $self->_set_mech($mech);
    return $mech;
}

has base => (
    is => 'ro', isa => Str,
    builder => '_build_base',
    documentation =>
        'The base URL for tests',
);

sub _build_base ($self) {
    my $host = `hostname`;  chomp $host;
    my $port = $ENV{ACT_TEST_PORT} || 5050;
    return "http://$host:$port";
}

has home => (
    is => 'ro', isa => Str,
    default => sub { "$tempdir" },
    documentation =>
        'Where $ENV{ACTHOME} will point to',
);

sub _build_acthome ($self) {
    my $tempdir = File::Temp->newdir( CLEANUP => 0 );
    # The following will need adaption to the post-november master
    # Part 1: Link the distribution files from the repository so that
    # changes become immediately visible
    for my $dir (qw(templates po wwwdocs)) {
        symlink "$RealBin/../$dir","$tempdir/$dir"
            or die "Failed to create a symlink for '$RealBin/../$dir': '$!'";
    }
    # Part 2: Copy the files from the test environment
    for my $dir (qw(actdocs conf)) {
        dircopy "$RealBin/acthome/$dir","$tempdir/$dir";
    }
    # Part 3: These must just exist
    for my $dir (qw(photos ttc)) {
        mkdir "$tempdir/$dir" or die "Could not create '$tempdir/$dir': '$!'";
    }
    $ENV{ACTHOME} = $tempdir;
    return "$tempdir";
}

has smtp_server => (
    is => 'ro', isa => InstanceOf['Test::Act::SMTP::Server'],
    default => sub { $smtp_server },
    documentation =>
        'The (singleton) SMTP service for this test run',
);


# ----------------------------------------------------------------------

sub new_mech ($self) {
    my $mech = Test::WWW::Mechanize::PSGI->new(app => Act::Dispatcher->to_app);
    $self->_set_mech($mech);
    return $mech;
}

1;


__END__

=encoding utf8

=head1 NAME

Test::Act::Environment - Supply a testing environment for Act

=head1 SYNOPSIS

  use Test::Act::Environment;

  use Act::Store::Database;

  my $testenv     = Test::Act::Environment->new;
  my $base        = $testenv->base;
  my $smtp_server = $testenv->smtp_server;
  my $mech        = $testenv->mech;

  # mech tests
  $mech->get_ok("$base/$conference/main");
  $mech->content_like(qr(whatever));

  # renew the mech to get rid of cookies
  $mech = $testenv->new_mech;

  # After submitting a form which sends an email
  my $mail = $smtp_server->next_mail;
  like($mail->{message},qr/password/);

=head1 DESCRIPTION

This module provides an environment which can be used for
application-level testing of Act.  It provides the folliwing helpers:

=over

=item base - a directory suited for C<$ENV{ACTHOME}>

This directory is contains a minimal setup of the files and
directories to run Act.  It is a temporary directory, so tests may
alter files therein (in particular, act.ini), at will to suit their
tests.
B<This is especially true if you don't have a local database connection.>

Later, utilities to munge parts of act.ini might be available with
this module.

=item smtp_server - a tiny handler for mails sent by Act

This server captures mails sent by act
I<for the current test run only>
by manipulating the configuration in L<Act::Email>.  It does not
collide with a "real" SMTP server or with other tests running in
parallel.

The server is for automated tests only, all mails are gone after the
test ends.

=item mech - A L<Test::WWW::Mechanize::PSGI> object to run the test.

This might be extended later to allow HTTP-tests over the network buy
just replacing the mech by a L<Test::WWW::Mechanize> object.

=back

=head1 METHODS

=head2 Method new_mech

Replaces the mech object by a fresh one, thereby killing the cookie
jar and starting with a fresh history

=cut

=head1 ENVIRONMENT

When sending mail, L<Act::Email> respects the environment variables
SMTP_HOST and SMTP_PORT which take precedence over the configuration.
Don't set these if you want to use this module's SMTP server.

=head1 FILES

The files to setup the test environment are copied from t/acthome.

=head1 AUTHOR

Harald Jörg, haj@posteo.de

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
