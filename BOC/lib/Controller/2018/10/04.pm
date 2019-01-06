package BOC::Controller::2018::10::04;
use Moose;
use namespace::autoclean;
use JSON;
use utf8;
use Encode;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

BOC::Controller::2018::10::04 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index
返回全校职工的个人工作量
请求参数：无
响应参数：{"RTN_CODE":"01",DATA:[{"ZGH":" ","XM":" ","XN":" ","ZC":" ","DW":" ","LL":" ","SY":" ","QT":" ","LW":" ","CXZX": " ","GJC":" ","ZGS":" "}],"RTN_MSG":"成功！"}
=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $reply;
	my $json = $c->req->body_data;
#    $json->{XM} =encode("gbk",decode("utf8",$json->{XM}));
	my $sql = "select xm,sum(ll) ll,sum(sy) sy,sum(qt) qt,sum(lw) lw,sum(cxzx) cxzx,sum(gjc) gjc,sum(zgs) zgs from v_gzlcx_gr where xm=\'$json->{XM}\' group by xm ";
	my $data = $c->forward('/urpdb/search',["$sql"]);
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
