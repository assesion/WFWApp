package BOC::Controller::2018::10::07;
use Moose;
use namespace::autoclean;
use utf8;
use JSON;
use Encode;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

BOC::Controller::2018::10::07 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index
校级折线图
无参数
响应参数{"RTN_CODE":"00","DATA":[{"XN":"***","ZGS":"70.5"}],"RTN_MSG":"成功！"}
=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $reply;
	my $sql = "select * from v_gzlcx_xx_sd";
	my $data = $c->forward('/urpdb/search', ["$sql"]);
	if ( $data ) {
        $reply->{"RTN_CODE"} = "00";
	    $reply->{"RTN_MSG"} = "成功！";
        $reply->{"DATA"} = $data;
	}
	else {
		$reply->{"RTN_CODE"} = "01";
		$reply->{"RTN_MSG"} = "查询失败！";
	}
    $c->response->body(encode_json($reply));
}



=encoding utf8

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
