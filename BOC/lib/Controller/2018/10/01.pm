package BOC::Controller::2018::10::01;
use Moose;
use namespace::autoclean;
use JSON;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

BOC::Controller::2018::10::01 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index
根据职工号ZGH查询职工权限
请求参数 ：{ZGH:"12345"}
响应参数：{"RTN_CODE":"00",DATA:[{"QX":"1","DWDM";"206"}],"RTN_MSG":"成功！"}
=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $json = $c->req->body_data;
	my $reply;
	my $sql = "select zgh,xm,dw,qx from v_gzlcx_gr where zgh=\'$json->{ZGH}\' order by qx desc";
	my $data = $c->forward('/urpdb/search', ["$sql"]);
#    $data = $data->[0];
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
