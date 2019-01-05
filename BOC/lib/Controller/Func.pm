package BOC::Controller::Func;
use Moose;
use namespace::autoclean;
use Encode qw/encode decode/;
use JSON;
use Date::Calc qw(:all);
use POSIX qw(strftime);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

BOC::Controller::Func - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BOC::Controller::Func in Func.');
}

=head2 xiaoli
校历查询
=cut

sub xiaoli : Private {
    my ( $self, $c, $date ) = @_;
    my $reply;
    my $sql = "SELECT wid,xnxqdm,xlksrq,xljsrq from usr_gxsj.t_xx_xl";
    my $data = $c->forward('/urpdb/search', ["$sql"]);
    if ( $data ) {
        for (my $i=0; $i<=$#{$data}; $i++) {
            my ($day, $month, $year) = split("-",$data->[$i]->{XLJSRQ});
            $month =~ s/\D+//;
            my $reply->{dqz} = int Delta_Days("20" . $year, $month, $day, split("-", $date))/7;
            if ( $reply->{dqz} <= 0 ) {
                my $reply->{dow} = Day_of_Week(split("-", $date));
                ($day, $month, $year) = split("-",$data->[$i]->{XLKSRQ});
                $month =~ s/\D+//;
                $reply->{dqz} = int Delta_Days("20" . $year, $month, $day, split("-", $date))/7;
                    if ( $data->[$i]->{XNXQDM} =~ /^(\d{4}-\d{4})-(\d)$/ ) {
                        ($reply->{xn}, $reply->{xq}) = ($1, $2);
                    }
                    return $reply;
            }
        }
    }
    return $reply;
}

=head2 pingjiao
评教状态查询
=cut

sub pingjiao : Private {
    my ( $self, $c, $xh ) = @_;
    my $sql = "SELECT t.cpr from usr_gxsj.V_FROM_JW_JXPG_CPRB t WHERE t.cpr=\'$xh\'";
    my $data = $c->forward('/urpdb/search', ["$sql"]);
    my $reply = 0;
    if ( $data ) {
        for (my $i=0; $i<=$#{$data}; $i++) {
            $reply++;
        }
    }
    return $reply;
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
