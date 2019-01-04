package SCUEC::View::HTML5;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        SCUEC->path_to( 'root', 'src' ),
        SCUEC->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    render_die   => 1,
    ENCODING     => 'utf-8',
});

=head1 NAME

SCUEC::View::HTML5 - Catalyst TT Twitter Bootstrap View

=head1 SYNOPSIS

See L<SCUEC>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

edu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

