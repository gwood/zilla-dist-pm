# ABSTRACT: Dist::Zilla Bashed Inside Out
use strict;
package Zilla::Dist;

use File::Share;
use IO::All;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, @args) = @_;
    $self->usage unless @args == 1;
    my $cmd = shift @args;
    my $method = "do_$cmd";
    $self->usage unless $self->can($method);
    $self->$method(@args);
}

sub do_setup {
    my ($self, @args) = @_;

    my $sharedir = $self->find_sharedir;

    my $makefile_content = io->file("$sharedir/Makefile")->all;
    io->file('Makefile')->print($makefile_content);

    my $meta_content = io->file("$sharedir/Meta")->all;
    io->file('Meta')->print($meta_content);

    print <<'...';
Zilla::Dist created files: Makefile and Meta.
...
}

sub do_sharedir {
    my ($self, @args) = @_;
    print $self->find_sharedir . "\n";
}

sub find_sharedir {
    my ($self, @args) = @_;
    my $sharedir = File::Share::dist_dir('Zilla-Dist');
    -d $sharedir or die "Can't find Zilla::Dist share dir";
    return $sharedir;
}

sub usage {
    die <<'...';
Usage:

    zild setup          # Create a new Zilla::Dist Makefile and Meta
    zild sharedir       # Print the location of the Zilla::Dist share dir
...
}

1;
