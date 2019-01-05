package BOC::Controller::Root;
use Moose;
use namespace::autoclean;
use Encode;
use JSON;
use POSIX qw(strftime);

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

BOC::Controller::Root - Root Controller for BOC

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->req->address eq '' ) {
        my $json = uc $c->req->params->{Json} || '';
        my $month = strftime "%Y%m", localtime;
        my $file = '/tmp/boc' . $month . '.log';;
        my $fh = IO::File->new(">> $file");
        if ( defined $fh ) {
            if ( $json ) {
                print $fh "$json\t";
            }
            my $now = strftime "%F %X", localtime;
            print $fh $now,"\t",$c->req->address,"\n";
            undef $fh;
        }

        my $reply;
        my $info = decode_json(encode("utf8",$json));
        if ( $info->{TRAN_CODE} eq "XY0001" ) {
            $reply = $c->forward('urpdb/xy0001', ["$json"]);
        }
        elsif ( $info->{TRAN_CODE} eq "XY0004" ) {
            $reply = $c->forward('urpdb/xy0004', ["$json"]);
        }
        elsif ( $info->{TRAN_CODE} eq "XY0007" ) {
            $reply = $c->forward('urpdb/xy0007', ["$json"]);
        }
        elsif ( $info->{TRAN_CODE} eq "XY0008" ) {
            $reply = $c->forward('urpdb/xy0008', ["$json"]);
        }
        elsif ( $info->{TRAN_CODE} eq "XY0009" ) {
            $reply = $c->forward('urpdb/xy0009');
        }
        elsif ( $info->{TRAN_CODE} eq "XY0010" ) {
            $reply = $c->forward('urpdb/xy0010', ["$json"]);
        }
        else {
            $reply->{"RTN_CODE"} = "100";
            $reply->{"RTN_MSG"} = decode("utf8","无此交易类型！");
        }
        $reply->{"TRAN_CODE"} = $info->{TRAN_CODE};
        $c->response->body(decode("utf8",encode_json($reply)));
    }
    else {
        $c->response->body($c->req->address);
    }
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head2 auto

Check if there is a user and, if not, forward to login page

=cut

sub auto : Private {
    my ( $self, $c ) = @_;
    my $i = 0;
    
    unless ( $c->action() eq '/' ) {
        if ( $c->req->method eq 'POST' && $c->req->content_type eq 'application/json' ) {
            if ( $c->req->address eq '' || $c->req->headers->header("appId") eq '' ) {
                $i = 1;
            }
        }
        unless ( $i ) {
            $c->res->status( 401 );
            $c->res->body( 'Access Denied' );
            return 0;
        }
    }
}

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
