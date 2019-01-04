package SCUEC::Controller::2018::03;
use Moose;
use namespace::autoclean;
use LWP::UserAgent;
use utf8;
use Spreadsheet::ParseExcel;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

SCUEC::Controller::2018::03 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->res->redirect("http://www.scuec.edu.cn/.403");
}

=head2 t20
t20(财务开发票信息)
=cut

sub t20 : Local {
    my ( $self, $c ) = @_;
    my $content;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my $surl = "http://www.scuec.edu.cn/s/33/t/902/84/63/info99427.htm";
    my $response = $ua->get($surl);
    if ( $response->is_success ) {
        $content = $response->decoded_content;
        if ( $content =~ /\<div class=\"pagesnrbt\"\>.*?\<h3\>(.*?)\<\/h3\>.*?\<\/div\>.*(\<div class=\"pagesnr\"\>.*?\<\/div\>)/s ) {
            $c->stash->{title} = $1;
            $content = $2;
        }
    }
    $c->stash->{message} = $content;
    $c->stash->{surl} = $surl;
    $c->stash->{template} = 'table.tt2';

#    $c->response->body($content);
}

=head2 f30
差旅标准
=cut

sub f30 : Local {
    my ( $self, $c ) = @_;
    my $surl = "http://www.gov.cn/xinwen/2016-04/14/content_5064000.htm";
    $c->stash->{surl} = $surl;
    my $select = $c->req->params->{i} || 1;
    my $parser   = Spreadsheet::ParseExcel->new();
    my $workbook = $parser->parse('/home/edu/etc/9871fef5752c4584a42652298846cd71.xls');
 
    if ( !defined $workbook ) {
        die $parser->error(), ".\n";
    }
    my $worksheet = $workbook->worksheet(0); 
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    my $json;
    my $i = 0;
    my $max;
    my $cell;
    
    for my $row ( $row_min .. $row_max ) {
        $cell = $worksheet->get_cell($row, 0);
        next unless $cell;
        if ( $cell->value() =~ /\d+/ ) {
            $i = $cell->value();
            $json->{$i}->{begin} = $row;
            $json->{$i - 1}->{end} = $row - 1 if ( $i > 1 );
        }
    }
    $json->{$i}->{end} = $row_max;
    $max = $i;
    $select = 1 if ( $select > $max || $select < 1 );
    for $i ( 1 .. $max ) {
        my $n = 0;
        my $w = 0;
        for my $row ( $json->{$i}->{begin} .. $json->{$i}->{end} ) {
            for my $col ( 1 .. $col_max ) {
                $cell = $worksheet->get_cell($row, $col);
                next unless $cell;
                if ( $cell->value() ) {
                    $json->{$i}->{add} = $cell->value() if ( $col == 1 );
                    $json->{$i}->{n}->[$n]->{city} = $cell->value() if ( $col == 2 );
                    $json->{$i}->{n}->[$n]->{l1} = $cell->value() if ( $col == 3 );
                    $json->{$i}->{n}->[$n]->{l2} = $cell->value() if ( $col == 4 );
                    $json->{$i}->{n}->[$n]->{l3} = $cell->value() if ( $col == 5 );
                    $json->{$i}->{w}->[$w]->{city} = $cell->value() if ( $col == 6 );
                    $json->{$i}->{w}->[$w]->{date} = $cell->value() if ( $col == 7 );
                    $json->{$i}->{w}->[$w]->{l1} = $cell->value() if ( $col == 8 );
                    $json->{$i}->{w}->[$w]->{l2} = $cell->value() if ( $col == 9 );
                    $json->{$i}->{w}->[$w]->{l3} = $cell->value() if ( $col == 10 );
                }
            }
            $n++ if ( $json->{$i}->{n}->[$n] );
            $w++ if ( $json->{$i}->{w}->[$w] );
        }
    }
    $c->stash->{json} = $json;
    $c->stash->{select} = $select;
    $c->stash->{title} = "差旅住宿标准明细表";
    $c->stash->{template} = '2018/03/f30.tt2';
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
