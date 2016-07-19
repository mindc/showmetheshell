#!/usr/bin/perl

use strict;
use warnings;

use lib qw( lib/ );
use Plack::App::Net::Async::WebSocket;
use JSON::XS;
use HTML::FromANSI::Tiny;
use Term::VT102;
use IO::Tty::Util qw( forkpty );

my $term = 'screen';

my $js_keycodes = { 
	8 => 'key_backspace',

    33 => 'key_ppage',
    34 => 'key_npage',

    35 => 'key_end',
    36 => 'key_home',

    37 => 'key_left',
    38 => 'key_up',
    39 => 'key_right',
    40 => 'key_down',

    45 => 'key_ic',
    46 => 'key_dc',

    112 => 'key_f1',
    113 => 'key_f2',
    114 => 'key_f3',
    115 => 'key_f4',
    116 => 'key_f5',
    117 => 'key_f6',
    118 => 'key_f7',
    119 => 'key_f8',
    120 => 'key_f9',
    121 => 'key_f10',
    122 => 'key_f11',
    123 => 'key_f12',

 };

my $term_keycodes = {};

my @infocmp = `infocmp $term -L1`;

foreach my $entry ( @infocmp ) {
    $entry =~ s/\s*|,$//g;
    my ( $id, $esc ) = split '=', $entry;
    next unless $id =~ m/^key_/;
    $esc =~ s/E/e/;
    $term_keycodes->{$id} = $esc;
}

$Data::Dumper::Indent = 1;

my $h = HTML::FromANSI::Tiny->new(
	auto_reverse => 0, 
	background => 'black', 
	foreground => 'silver', 
	html_encode =>  sub { shift }
);

$SIG{CHLD} = \&REAPER;

sub REAPER {
    while ( ( my $kid = waitpid(-1, POSIX::WNOHANG) ) > 0 ) {
#		print STDERR "[WAIT FOR CHLD] $kid\n";
	}
    $SIG{CHLD} = \&REAPER;
}

my $app = Plack::App::Net::Async::WebSocket->new(
	on_handshake => sub {
		my $ws = shift;

		$ws->{history} = [];
		my $vt = Term::VT102->new(cols => 132, rows => 36);
		$vt->option_set('LFTOCRLF', 1);
		$vt->option_set('LINEWRAP', 1);

		my ( $pid, $pty ) = forkpty( $vt->rows, $vt->cols, "env TERM=$term /bin/bash --login" );

		$ws->{shell_pid} = $pid;

		my $changedrows = {};

		my $stream = IO::Async::Stream->new(
			encoding => 'utf8',
		    handle => $pty,
			on_closed => sub {
				$ws->close;
			},
		    on_read => => sub {
        		my ( $handle, $buffref ) = @_;
		        $vt->process( $$buffref );

		        foreach my $row ( sort { $a <=> $b } keys %$changedrows ) {
	       		    my $text = $vt->row_sgrtext($row);
		            delete $changedrows->{$row};
					$text = $h->html($text);
        		    $ws->send_frame( JSON::XS->new->encode( { type => 'row', row => $row+0, text => $text } ) );
        		}

				my ( $x, $y ) = $vt->status;
				$ws->send_frame( JSON::XS->new->encode( { type => 'cursor', x => $x, y => $y } ) );

		        $$buffref = '';
        		return 0;
    		}
		);

		$ws->add_child( $stream );

		$ws->{shell} = $stream;

		$vt->callback_set(
		    OUTPUT => sub {
        		my ($vtobject, $type, $arg1, $arg2, $private) = @_;
		        if ($type eq 'OUTPUT') {
        		    $private->write($arg1);
				}
		    } => $stream
		);

		$vt->callback_set('ROWCHANGE',   \&_vt_rowchange, $changedrows);
		$vt->callback_set('CLEAR',       \&_vt_changeall, $changedrows);
		$vt->callback_set('SCROLL_UP',   \&_vt_changeall, $changedrows);
		$vt->callback_set('SCROLL_DOWN', \&_vt_changeall, $changedrows);
#		$vt->callback_set('GOTO',        \&_vt_cursormove, $ws);
		$vt->callback_set('UNKNOWN',   \&_vt_debug, $ws );

	},
	on_frame => sub {
		my ( $ws, $message ) = @_;

		eval {
			$message = JSON::XS->new->decode( $message );

			if ( $message->{type} eq 'key' ) {
				key( $ws->{shell}, $message->{code} );
			} elsif ( $message->{type} eq 'char' ) {
				char( $ws->{shell}, $message->{code} );
			}
		};
		print "[ERROR] " . $@ . "\n" if $@;
	},
	on_closed => sub {
		kill 'TERM' => shift->{shell_pid};
	}
)->to_app;

sub _vt_debug
{
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;
	$private->send_frame( JSON::XS->new->encode( { type => 'debug', data => [ @_[1..3] ] } ) );
}

sub _vt_rowchange {
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;
    $private->{$arg1} = time if (not exists $private->{$arg1});
}

sub _vt_changeall {
    my ($vtobject, $type, $arg1, $arg2, $private) = @_;

    for (my $row = 1; $row <= $vtobject->rows; $row++) {
        $private->{$row} = 0;
    }
}

sub _vt_cursormove {
    my ($vtobject, $type, $arg1, $arg2, $ws) = @_;
	my $r = {type => 'cursor', x => $arg1, y => $arg2} ;
    $ws->send_frame( JSON::XS->new->encode( $r ) );
}


sub key {
    my $stream = shift;
    my $code = shift;

	if ( $js_keycodes->{ $code } ) {
	    if ( my $esc = $term_keycodes->{ $js_keycodes->{ $code } } ) {
		    $stream->write( eval "qq#$esc#" );
		}
	} else {
	    $stream->write( chr($code) );
	}

}

sub char {
    my $stream = shift;
    my $code = shift;

    my $buffer;

    if ($code < 128) {
        $buffer = pack('C', $code);
    }
    elsif ($code > 128 && $code < 2048) {
        my $one = ($code >> 6) | 192;
        my $two = ($code & 63) | 128;
        $buffer = pack('CC', $one, $two);
    }
    else {
        my $one   = (($code >> 12) | 224);
        my $two   = ((($code >> 6) & 63) | 128);
        my $three = (($code & 63) | 128);
        $buffer = pack('CCC', $one, $two, $three);
    }

    $stream->write($buffer);
}

