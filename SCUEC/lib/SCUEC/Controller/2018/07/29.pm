package SCUEC::Controller::2018::07::29;
use Moose;
use namespace::autoclean;
use LWP::UserAgent;
use JSON;
use utf8;
use POSIX qw(strftime);
use Encode;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

SCUEC::Controller::2018::07::29 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $json;
    $json->{SFRZH} = $c->req->param('uid') || $c->user->username();
	my $flag = $c->req->param('id')?1:0;
    my $pass;
    $pass->{server} = "http://apis.scuec.edu.cn";
    $pass->{url} = "$pass->{server}/2018/07/21";
    $pass->{appId} = ''; # 输入appId
    $pass->{accessToken} = ''; # 输入accessToken
    my $res = $c->forward('api', [$pass, $json]);
    if ( $res->[0]->{DM} eq '0' ) {
        $c->detach('xld', [$pass, $flag]);
    }
    elsif ( $res->[0]->{DM} eq '1' ) {
        $c->detach('yld', [$pass, $res->[0]->{DWDM}, $flag]);
    }
    elsif ( $res->[0]->{DM} eq '2' ) {
		$flag = 1 if ( $c->req->param('data') );
        if ( $flag ) {
			$c->detach('submit',[$pass, $c->req->param('data')]);
		}
		else {
			$c->detach('show',[$pass, $json->{SFRZH}]);
		}
    }
}

=head2
show
=cut

sub show : Private {
	my ( $self, $c, $pass, $XH) = @_;
	my $json;
	$json->{XH} = $XH;
	$pass->{url} = "$pass->{server}/2018/07/25";
	my $data = $c->forward('api',[$pass, $json]);
	try {
		foreach my $a ( @$data ) {
			last;
		}
	}
	catch {
		$c->detach('err',['no_permission']);
	};
    $c->stash( data => $data, date => strftime("%Y",localtime()), template => '2018/07/29/zyz.tt2' );
}

=head2
submit
=cut

sub submit : Private {
	my ( $self, $c, $pass, $data ) = @_;
	$pass->{url} = "$pass->{server}/2018/07/26";
	my $json = from_json($data, {allow_nonref => 1});#转为hash
	try {
		$c->forward('api',[$pass, $json]);
		$c->res->body('1');
	}
	catch {
		$c->res->body('0');
	};
}

=head2
院领导相关函数
=cut

sub yld : Private {
	my ($self, $c, $pass, $dwdm, $flag) = @_;
	#学院到校情况饼图
	$pass->{url} = "$pass->{server}/2018/07/23";
	my $json;
	$json->{DWDM} = $dwdm;
	my $pie = $c->forward('api',[$pass, $json]);
	#各专业到校情况
	$pass->{url} = "$pass->{server}/2018/07/24";
	my $zy = $c->forward('api',[$pass, $json]);
	if ( $flag ) {#数据请求
		my $res;
		$res->{pie} = $pie->[0];
		$res->{zy} = $zy;
		$c->response->body(to_json($res,{allow_nonref => 1}));
	}
	else {#页面渲染
		$c->stash(data => $zy,pie => $pie->[0], date => strftime("%Y",localtime()), dwdm => $dwdm, template => '2018/07/29/yyx.tt2');
	}
}

=head2
校领导相关显示
=cut

sub xld : Private {
	my ( $self, $c, $pass, $flag ) = @_;
	$pass->{url} = "$pass->{server}/2018/07/22";
    my $json;
	$json->{DWDM} = 'all';
	my $pie = $c->forward('api',[$pass, $json]);
    $pass->{url} = "$pass->{server}/2018/07/23";
	my $xy = $c->forward('api',[$pass, $json]);
	if ( $flag ) {
		my $res;
		$res->{pie} = $pie->[0];
		$res->{xy} = $xy;
		$c->response->body(to_json($res,{allow_nonref => 1}));
	}
	else {
		$c->stash(xy => $xy, res => $pie->[0], date => strftime("%Y",localtime()), template => '2018/07/29/xyx.tt2');
	}
}

=head2 api
通用接口访问函数，传入参数依次为pass->{url, appId, accessToken},json->{SFRZH}(可选）
=cut

sub api : Private {
    my ( $self, $c, $pass, $json ) = @_;
    my $reply;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    $ua->default_header("appId" => $pass->{appId}, "accessToken" => $pass->{accessToken});
    
    my $response = $ua->post($pass->{url},Content => to_json($json, {allow_nonref => 1}),Content_type =>'application/json');
    if ( $response->is_success ) {
        $reply = $response->decoded_content;
        my $data = from_json(decode("utf8", $reply), {allow_nonref => 1});
        if ($data->{RTN_CODE} eq '00') {
            return $data->{DATA};
        }
        else {
            $c->detach('err', ['dwdm']);
        }
    }
    else {
        $reply = $response->status_line;
        $reply .= $response->decoded_content;
        $c->detach('err', ['api']);
    }
}

=head2
错误函数
=cut

sub err : Private {
	my ( $self, $c, $info ) = @_;
	if ( $info eq 'dwdm') {	
        $c->stash( var => $info, template => '2018/07/29/dw_err.tt2' );
	}
	elsif ( $info eq 'api' ) {
        $c->stash( template => '2018/07/29/api_err.tt2' );
	}
	elsif ( $info eq 'no_permission' ) {
        $c->stash( template => '2018/07/29/no_permission.tt2' );
	}
	elsif ( $info eq 'zr' ) {
        $c->stash( template => 'error.tt2' );
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
