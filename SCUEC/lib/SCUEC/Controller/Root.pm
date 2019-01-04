package SCUEC::Controller::Root;
use Moose;
use namespace::autoclean;
use LWP::UserAgent;
use JSON;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

SCUEC::Controller::Root - Root Controller for SCUEC

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->stash->{template} = 'welcome.tt2';
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->res->redirect("http://www.scuec.edu.cn/404");
}

=head2 EmployeeAuth
EmployeeAuth()
=cut

sub EmployeeAuth : Local {
    my ( $self, $c, $code ) = @_;
    $code = $c->req->params->{code} unless ( $code );
    my $userid = $c->user->get("username");
    if ( $userid && $code ) {
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->env_proxy;
        my $response = $ua->get("http://210.42.144.39/qywx/EmployeeAuth?code=$code&userid=$userid");
        if ( $response->is_success ) {
            my $reply = $response->decoded_content;
            $c->log->info($reply);
            my $json = decode_json($reply);
            unless ( $json->{errcode} ) {
                $c->log->info($code);
                $c->response->body("欢迎 $userid ！成功绑定中南民族大学企业微信！");
            }
        }
    }
    $c->response->body("$userid 绑定失败！");
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
    
    unless ( $c->user_exists || $c->authenticate ) {
        $c->res->redirect("http://www.scuec.edu.cn/.403");
        return 0;
    }
}

=head1 AUTHOR

yusuf,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
