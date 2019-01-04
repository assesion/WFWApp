package SCUEC::Controller::2018::12::19;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use LWP;
use JSON;
use utf8;
use Encode;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

SCUEC::Controller::2018::12::19 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index
主函数
=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    
	my $pass;
	my $XH = $c->user->username() || $c->req->param('uid');
	$pass->{XH} = $XH;
	$pass->{token_url} = "http://apis.scuec.edu.cn/2018/12/18";
	my $res = $c->forward('api',[$pass]);
	if ( $res ne '1' ) {#已经填写过
		$c->detach('err',["ytg"]);
	}
	if ( $c->req->method eq "POST" and $res eq '1' ) {
		my $data = $c->req->parameters;
		$pass->{XH} = $XH;
		$pass->{DM} = '1';
		$pass->{post_data} = $data;
		$c->forward('api', [$pass]);
		$c->response->body("提交成功!");
		return 1;
	}
	$pass->{token_url} = "http://apis.scuec.edu.cn/2018/12/17";
	my $data = $c->forward('api',[$pass]);#获取问题数据
	my $danx = $data->{DATA_1};# 单选题
	my $duox = $data->{DATA_2};# 多选题
	my $jd = $data->{DATA_3}; # 简答题
    $c->stash( template=>"2018/12/19/question.tt2",
                danx=>$danx,
				duox=>$duox,
				jd=>$jd,
	);
}

=head1
错误函数
=cut

sub err :Private {
	my ( $self, $c, $info ) = @_;
	if ( $info eq 'api_err' ) {
		$c->stash(	template=>'2018/12/19/error.tt2',
					info=>"服务器开小差0.0",
		);
	}
	if ( $info eq "ytg" ) {
		$c->stash(	template=>'2018/12/19/error.tt2',
					info=>"您已填写过该问卷",
		);
	}
}

=head1
api函数
=cut

sub api :Private { #通用接口访问函数，传入参数依次为url，appid，Token,SFRZH(可选）
	my ( $self, $c, $recv) = @_;
    
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);#连接延时
	my $response;#接受返回数据
	my $data;# 接受返回的json数据
	my $json;# 进行数据传输封装
	my $url; # 传入的接口链接
	$url = $recv->{token_url};
	$json->{appId} = '';
	$json->{accessToken} = '';
	if ( $recv->{post_data} ) {
		$json->{data} = $recv->{post_data};
	}
	if ( $recv->{DM} ) {
		$json->{DM} = $recv->{DM};
	}
	if ( $recv->{XH} ) {
		$json->{XH} = $recv->{XH};
	}
	$ua->default_header("appId" => $json->{appId}, "accessToken" => $json->{accessToken});#默认头
	delete $json->{'appId'};
	delete $json->{'accessToken'};
	$response = $ua->post($url,Content=>encode("utf8",to_json($json,{allow_nonref=>1})),Content_type =>'application/json');
	if ( $response->is_success ) {
		$data = from_json(decode("utf8",$response->decoded_content),{allow_nonref=>1});
		if ($data->{RTN_CODE} eq '01') { #未填过
			return 1;
		}
		return $data->{DATA};
	}
	else {
		$c->detach('err',['api_err']);
	}
}


=encoding utf8

=head1 AUTHOR

yusuf,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
