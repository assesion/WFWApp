package BOC::Controller::2018::10::05;
use Moose;
use namespace::autoclean;
use JSON;
use utf8;
use Encode;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

BOC::Controller::2018::10::05 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index
根据单位代码DW查询该单位所有职工的姓名
请求参数：{"DWDM":"123"}
响应参数：{"RTN_CODE":"01",DATA:[{"ZGH":" ","XM":" ","XN":" ","ZC":" ","DW":" ","LL":" ","SY":" ","T":" ","LW":" ","CXZX": " ","GJC":" ","ZGS":" "}],"RTN_MSG":"成功！"}
=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $json = $c->req->body_data;
	my $reply;
	$json->{DW} =encode("gbk",decode("utf8",$json->{DW}));
	my $sql = "select distinct (xm) from v_gzlcx_gr where dw=\'$json->{DW}\'";
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
