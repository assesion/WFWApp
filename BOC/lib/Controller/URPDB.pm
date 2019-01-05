package BOC::Controller::URPDB;
use Moose;
use namespace::autoclean;
use Encode;
use JSON;
use DBI;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

#$ENV{NLS_LANG} = "SIMPLIFIED CHINESE_CHINA.ZHS16GBK";
$ENV{NLS_LANG} = "SIMPLIFIED CHINESE_CHINA.AL32UTF8";
$ENV{ORACLE_HOME} = "/u01/app/oracle/product/11.2.0/dbhome_1/";

=head1 NAME

BOC::Controller::URPDB - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BOC::Controller::URPDB in URPDB.');
}

=head2 xy0001

=cut

sub xy0001 : Private {
    my ( $self, $c, $json ) = @_;
    my $info = decode_json(encode("utf8",$json));
    my $reply;
    if ( $info->{ZJH} =~ /^\d{15}$/ || $info->{ZJH} =~ /^\d{18}$/ || $info->{ZJH} =~ /^\d{17}X$/ ) {
        if ( $info->{JS} eq "1" || $info->{JS} eq "2" ) {
            my $sql = "SELECT * FROM usr_gxsj.v_exy_user WHERE zjh = \'$info->{ZJH}\' ORDER by zgh desc";
            my $data = $c->forward('search', ["$sql"]);
            if ( $data ) {
                        $reply = $data->[0];
                if ( $reply->{JS} eq $info->{JS} ) {
                    if ( $reply->{XM} eq $info->{XM} ) {
                        $reply->{"RTN_CODE"} = "00";
                        $reply->{"RTN_MSG"} = decode("utf8","成功！");
                    }
                    else {
                        $reply->{"RTN_CODE"} = "01";
                        $reply->{"RTN_MSG"} = decode("utf8","姓名不一致！");
                    }
                }
                else {
                    $reply->{"RTN_CODE"} = "02";
                    $reply->{"RTN_MSG"} = decode("utf8","角色不一致！");
                }
            }
            else {
                $reply->{"RTN_CODE"} = "03";
                $reply->{"RTN_MSG"} = decode("utf8","无此用户信息！");
            }
        }
        else {
            $reply->{"RTN_CODE"} = "04";
            $reply->{"RTN_MSG"} = decode("utf8","角色类型不正确！");
        }
    }
    else {
        $reply->{"RTN_CODE"} = "05";
        $reply->{"RTN_MSG"} = decode("utf8","身份证格式不正确！");
    }
    return $reply;
}

=head2 xy0004
一卡通消费查询
=cut

sub xy0004 : Private {
    my ( $self, $c, $json ) = @_;
    my $info = decode_json(encode("utf8",$json));
    my $reply;
    if ( $info->{YKTZH} =~ /^\d+$/ ) {
        if ( $info->{JLS} <= 100 && $info->{JLS} > 0 ) {
            if ( $info->{QSRQ} =~ /^\d{4}-\d{2}-\d{2}$/ && $info->{JZRQ} =~ /^\d{4}-\d{2}-\d{2}$/ ) {
                my $sql = "SELECT z.sfrzh,s.shmc,l.mc as jylx,t.jyje,t.jyye,t.jysj,t.ljjycs
                            from usr_gxsj.t_ykt_grjy t,usr_gxsj.t_ykt_jylx l,usr_gxsj.t_ykt_sh s,usr_gxsj.t_ykt_zh z
                            WHERE t.yktzh=z.yktzh and t.jylx=l.dm and t.shdm=s.shdm(+) and l.dm<>'16'
                                and z.sfrzh=\'$info->{YKTZH}\' and t.jysj>\'$info->{QSRQ}\' and t.jysj<\'$info->{JZRQ}\'
                            order by t.jysj desc";
                if ( $info->{CXLX} == 1 ) {
                    $sql = "SELECT z.sfrzh,s.shmc,l.mc as jylx,t.jyje,t.jyye,t.jysj,t.ljjycs
                            from usr_gxsj.t_ykt_grjy t,usr_gxsj.t_ykt_jylx l,usr_gxsj.t_ykt_sh s,usr_gxsj.t_ykt_zh z
                            WHERE t.yktzh=z.yktzh and t.jylx=l.dm and t.shdm=s.shdm(+) and l.dm<>'16' and t.jyje<0
                                and z.sfrzh=\'$info->{YKTZH}\' and t.jysj>\'$info->{QSRQ}\' and t.jysj<\'$info->{JZRQ}\'
                            order by t.jysj desc";
                }
                elsif ( $info->{CXLX} == 2 ) {
                    $sql = "SELECT z.sfrzh,s.shmc,l.mc as jylx,t.jyje,t.jyye,t.jysj,t.ljjycs
                            from usr_gxsj.t_ykt_grjy t,usr_gxsj.t_ykt_jylx l,usr_gxsj.t_ykt_sh s,usr_gxsj.t_ykt_zh z
                            WHERE t.yktzh=z.yktzh and t.jylx=l.dm and t.shdm=s.shdm(+) and l.dm<>'16' and t.jyje>0
                                and z.sfrzh=\'$info->{YKTZH}\' and t.jysj>\'$info->{QSRQ}\' and t.jysj<\'$info->{JZRQ}\'
                            order by t.jysj desc";
                }
                my $data = $c->forward('search', ["$sql"]);
                if ( $data ) {
                    $reply->{"RTN_CODE"} = "00";
                    $reply->{"RTN_MSG"} = decode("utf8","成功！");
                    $reply->{ZBS} = $#{$data};
                    my $qsxh = 0;
                    $qsxh = $info->{QSXH} - 1 if ($info->{QSXH});
                    my $recode = $qsxh + $info->{JLS} - 1;
                    if ( $recode >= $reply->{ZBS} ) {
                        $recode = $reply->{ZBS};
                        $reply->{JLBJ} = 'N';
                    }
                    else {
                        $reply->{JLBJ} = 'Y';
                    }
                    my $zje = 0;
                    for (my $i=$qsxh; $i<=$recode; $i++) {
                        ($reply->{"DETAIL"}->[$i]->{"DATE"},$reply->{"DETAIL"}->[$i]->{"TIME"}) = split(' ',$data->[$i]->{JYSJ});
                        $reply->{"DETAIL"}->[$i]->{"AMOUNT"} = abs $data->[$i]->{JYJE}/100;
                        $reply->{"DETAIL"}->[$i]->{"ADDRESS"} = $data->[$i]->{SHMC} || decode("utf8","充值");
                        $reply->{"DETAIL"}->[$i]->{"JYYE"} = $data->[$i]->{JYYE}/100;
                        $zje += $data->[$i]->{JYJE}/100;
                    }
                    $reply->{ZJE} = abs $zje;
                    
                }
                else {
                    $reply->{"RTN_CODE"} = "04";
                    $reply->{"RTN_MSG"} = decode("utf8","无$info->{QSRQ}至$info->{JZRQ}一卡通消费信息！");
                }
            }
            else {
                $reply->{"RTN_CODE"} = "03";
                $reply->{"RTN_MSG"} = decode("utf8",'起止日期类型不正确！应为"xxxx-xx-xx"。');
            }
        }
        else {
            $reply->{"RTN_CODE"} = "02";
            $reply->{"RTN_MSG"} = decode("utf8",'查询记录数量过大！应<=100。');
        }
    }
    else {
        $reply->{"RTN_CODE"} = "01";
        $reply->{"RTN_MSG"} = decode("utf8","一卡通账号格式不正确！");
    }
    return $reply;
}

=head2 xy0007
课表查询
=cut

sub xy0007 : Private {
    my ( $self, $c, $json ) = @_;
    my $info = decode_json(encode("utf8",$json));
    my $reply;
    if ( $info->{XH} =~ /^\d+$/ ) {
        if ( $info->{YEAR} =~ /^\d{4}-\d{4}$/ ) {
            if ( $info->{XQ} eq "1" || $info->{XQ} eq "2" ) {
                my $sql = "SELECT * FROM usr_gxsj.t_bzks_xsxk x, usr_gxsj.v_pub_kcb k
                        WHERE x.xh = \'$info->{XH}\' and x.jxbh=k.jxbh and k.kkxn = \'$info->{YEAR}\' and k.kkxq = \'$info->{XQ}\'";
                my $data = $c->forward('search', ["$sql"]);
                if ( $data ) {
                    $reply->{"RTN_CODE"} = "00";
                    $reply->{"RTN_MSG"} = decode("utf8","成功！");
                    for (my $i=0; $i<=$#{$data}; $i++) {
                        my $j = $#{$reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}} + 1;
                        if ($j > 0) {
                            if ($reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j-1]->{"COURSESECTION"} eq decode("utf8","第$data->[$i]->{KSJC}-$data->[$i]->{JSJC}节")) {
                                if ($reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j-1]->{"COURSEWEEK"} eq decode("utf8","第$data->[$i]->{QSZ}-$data->[$i]->{ZZZ}周")) {
                                    if ($reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j-1]->{"COURSENAME"} eq $data->[$i]->{KCMC}) {
                                        if ($reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j-1]->{"COURSEADDRESS"} eq $data->[$i]->{JXLMC} . $data->[$i]->{JSMC}) {
                                            $reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j-1]->{"COURSETEACHER"} .= ",$data->[$i]->{JSXM}";
                                            next;
                                        }
                                    }
                                }
                            }
                        }
                        $reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j]->{"COURSESECTION"} = decode("utf8","第$data->[$i]->{KSJC}-$data->[$i]->{JSJC}节");
                        $reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j]->{"COURSENAME"} = $data->[$i]->{KCMC};
                        $reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j]->{"COURSETEACHER"} = $data->[$i]->{JSXM};
                        $reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j]->{"COURSEWEEK"} = decode("utf8","第$data->[$i]->{QSZ}-$data->[$i]->{ZZZ}周");
                        $reply->{"COURSE_PLAN"}->[$data->[$i]->{XQ}-1]->{"COURSE_LIST"}->[$j]->{"COURSEADDRESS"} = $data->[$i]->{JXLMC} . $data->[$i]->{JSMC};
                    }
                    my @week = ("周一","周二","周三","周四","周五","周六","周日");
                    for (my $i=0; $i<7; $i++) {
                        $reply->{"COURSE_PLAN"}->[$i]->{"WEEK"} = decode("utf8",$week[$i]);
                        $reply->{"COURSE_PLAN"}->[$i]->{"COURSE_LIST"} = [] unless ( $reply->{"COURSE_PLAN"}->[$i]->{"COURSE_LIST"} );
                    }
                }
                else {
                    $reply->{"RTN_CODE"} = "04";
                    $reply->{"RTN_MSG"} = decode("utf8","无$info->{YEAR}年第$info->{XQ}学期课程信息！");
                }
            }
            else {
                $reply->{"RTN_CODE"} = "03";
                $reply->{"RTN_MSG"} = decode("utf8","学期类型不正确！");
            }
        }
        else {
            $reply->{"RTN_CODE"} = "02";
            $reply->{"RTN_MSG"} = decode("utf8",'学年格式不正确！应为"xxxx-xxxx"，例"2014-2015"。');
        }
    }
    else {
        $reply->{"RTN_CODE"} = "01";
        $reply->{"RTN_MSG"} = decode("utf8","学号格式不正确！");
    }
    return $reply;
}

=head2 xy0008
成绩查询
=cut

sub xy0008 : Private {
    my ( $self, $c, $json ) = @_;
    my $info = decode_json(encode("utf8",$json));
    my $reply;
    if ( $info->{XH} =~ /^\d+$/ ) {
        if ( $info->{YEAR} =~ /^\d{4}$/ ) {
            if ( $info->{XQ} eq "1" || $info->{XQ} eq "2" ) {
                if ( $c->forward('/func/pingjiao', ["$info->{XH}"]) ) {
                    $reply->{"RTN_CODE"} = "05";
                    $reply->{"RTN_MSG"} = decode("utf8","$info->{YEAR}年第$info->{XQ}学期未评教，不能查询成绩信息！");
                    return $reply;
                }
                my $sql = "SELECT s.year,s.term,s.idsno,s.course,s.coursetype,s.score,s.credit from usr_gxsj.score s
                        WHERE s.idsno=\'$info->{XH}\' and s.year=\'$info->{YEAR}\' and s.term=\'$info->{XQ}\'";
                my $data = $c->forward('search', ["$sql"]);
                if ( $data ) {
                    $reply->{"RTN_CODE"} = "00";
                    $reply->{"RTN_MSG"} = decode("utf8","成功！");
                    for (my $i=0; $i<=$#{$data}; $i++) {
                        $reply->{"SCORE_LIST"}->[$i]->{"KCMC"} = $data->[$i]->{COURSE};
                        $reply->{"SCORE_LIST"}->[$i]->{"KCCJ"} = $data->[$i]->{SCORE};
                        $reply->{"SCORE_LIST"}->[$i]->{"KCXF"} = $data->[$i]->{CREDIT};
                        $reply->{"SCORE_LIST"}->[$i]->{"KCLX"} = $data->[$i]->{COURSETYPE};
                    }
                }
                else {
                    $reply->{"RTN_CODE"} = "04";
                    $reply->{"RTN_MSG"} = decode("utf8","无$info->{YEAR}年第$info->{XQ}学期成绩信息！");
                }
            }
            else {
                $reply->{"RTN_CODE"} = "03";
                $reply->{"RTN_MSG"} = decode("utf8",'学期类型不正确！应为"1"或"2"，例"XQ":"1"。');
            }
        }
        else {
            $reply->{"RTN_CODE"} = "02";
            $reply->{"RTN_MSG"} = decode("utf8",'学年格式不正确！应为"xxxx"，例"YEAR":"2015"。');
        }
    }
    else {
        $reply->{"RTN_CODE"} = "01";
        $reply->{"RTN_MSG"} = decode("utf8","学号格式不正确！");
    }
    return $reply;
}

=head2 xy0009
教学楼查询
=cut

sub xy0009 : Private {
    my ( $self, $c ) = @_;
    my $reply;
    my $sql = "SELECT t.jxlbh,t.jxlmc from usr_gxsj.t_jxl t";
    my $data = $c->forward('search', ["$sql"]);
    if ( $data ) {
        $reply->{"RTN_CODE"} = "00";
        $reply->{"RTN_MSG"} = decode("utf8","成功！");
        for (my $i=0; $i<=$#{$data}; $i++) {
            $reply->{"DETAIL"}->[$i]->{"JXLBH"} = $data->[$i]->{JXLBH};
            $reply->{"DETAIL"}->[$i]->{"JXLMC"} = $data->[$i]->{JXLMC};
        }
    }
    else {
        $reply->{"RTN_CODE"} = "01";
        $reply->{"RTN_MSG"} = decode("utf8","无教学楼信息！");
    }
    return $reply;
}

=head2 xy0010
空闲教室查询
=cut

sub xy0010 : Private {
    my ( $self, $c, $json ) = @_;
    my $info = decode_json(encode("utf8",$json));
    my $reply;
    if ( $info->{JXL} =~ /^\d+$/ ) {
        if ( $info->{RQ} =~ /^\d{4}-\d{2}-\d{2}$/ ) {
            my $xiaoli = $c->forward('/func/xiaoli', ["$info->{RQ}"]);
            if ( $xiaoli->{dqz} > 0 ) {
                if ( $info->{KSJC} && $info->{JSJC} ) {
                    my $sql ="SELECT l.jxlmc,s.lc,s.jsmc from usr_gxsj.t_js s, usr_gxsj.t_jxl l
                            WHERE s.jsdm not in (SELECT t.jsdm from usr_gxsj.v_pub_kcb t
                                WHERE t.kkxn = \'$xiaoli->{xn}\'
                                and t.kkxq = \'$xiaoli->{xq}\'
                                and t.jxlbh = \'$info->{JXL}\'
                                and t.qsz < \'$xiaoli->{dqz}\'
                                and t.zzz > \'$xiaoli->{dqz}\'
                                and t.xq = \'$xiaoli->{dow}\'
                                and t.ksjc >= \'$info->{KSJC}\'
                                and t.ksjc <= \'$info->{JSJC}\'
                            )
                            and s.jxldm = \'$info->{JXL}\' 
                            and s.jxldm = l.jxlbh";
                    my $data = $c->forward('search', ["$sql"]);
                    if ( $data ) {
                        $reply->{"RTN_CODE"} = "00";
                        $reply->{"RTN_MSG"} = decode("utf8","成功！");
                        for (my $i=0; $i<=$#{$data}; $i++) {
                            $reply->{"DETAIL"}->[$i]->{"JXLMC"} = $data->[$i]->{JXLMC};
                            $reply->{"DETAIL"}->[$i]->{"LC"} = $data->[$i]->{LC};
                            $reply->{"DETAIL"}->[$i]->{"JS"} = $data->[$i]->{JSMC};
                        }
                    }
                    else {
                        $reply->{"RTN_CODE"} = "05";
                        $reply->{"RTN_MSG"} = decode("utf8","无空闲教室信息！");
                    }
                }
                else {
                    $reply->{"RTN_CODE"} = "04";
                    $reply->{"RTN_MSG"} = decode("utf8",'节次类型不正确！例"KSJC":"1","JSJC":"2"');
                }
            }
            else {
                $reply->{"RTN_CODE"} = "03";
                $reply->{"RTN_MSG"} = decode("utf8",'当前时间为非学期内时间。');
            }
        }
        else {
            $reply->{"RTN_CODE"} = "02";
            $reply->{"RTN_MSG"} = decode("utf8",'日期格式不正确！应为"xxxx-xx-xx"，例"RQ":"2016-01-05"。');
        }
    }
    else {
        $reply->{"RTN_CODE"} = "01";
        $reply->{"RTN_MSG"} = decode("utf8","教学楼格式不正确！");
    }
    return $reply;
}

=head2 search

=cut

sub search : Private {
    my ( $self, $c, $sql ) = @_;
    my $reply;
    my $rtncode;
    if ( $sql ) {
            my $dbname = "dbpub";
            my $host = "";
            my $port = "1521";
            my $db = "dbi:Oracle:host=$host;sid=$dbname;port=$port";
            my $user = "";
            my $pwd = "";
            my $dbh = DBI->connect($db, $user, $pwd) or $rtncode = "000数据库连接失败！";
            my $i = 0;
            if ( $dbh ) {
                my $sth = $dbh->prepare("$sql");
                $sth->execute() or $rtncode = "001数据库查询失败！";
                while ( my $data = $sth->fetchrow_hashref ) {
                    foreach my $key ( sort keys %{$data} ) {
                        $reply->[$i]->{$key} = $data->{$key};
                    }
                    $i++;
                }
                $sth->finish;
                $dbh->disconnect();
            }
    }
    return $reply if $reply;
    return 0;
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
