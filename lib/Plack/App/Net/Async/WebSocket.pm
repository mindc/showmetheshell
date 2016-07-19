package Plack::App::Net::Async::WebSocket;

use strict;
use warnings;
use parent qw( Plack::Component );

use Protocol::WebSocket::Handshake::Server;
use Carp;

our $VERSION = '0.01';

sub Net::Async::HTTP::Server::Protocol::send_frame
{
	my ( $self, $frame ) = @_;
	$self->write( Protocol::WebSocket::Frame->new( $frame )->to_bytes );
}

sub new {
	my ( $class, @params ) = @_;
	my $self = $class->SUPER::new( @params );
	croak "on_frame param is mandatory" if not defined $self->{on_frame};
	return $self;
}

sub call
{
	my ( $self, $env ) = @_;

	my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi( $env );

	if ( !$hs->is_done ) {
		$hs->parse('');

		if ( $hs->error ) {
			if ( exists $self->{on_error} ) {
				$self->{on_error}->( $hs->error );
			}
			return [ 500,
				[ 'Content-Type' => 'text/plain' ],
				[ $hs->error ]];
		}

		if ( $hs->is_done ) {
			my $h = HTTP::Response->parse( $hs->to_string );
			return sub {
				my $responder = shift;
				my $writer = $responder->(
					[ 101, [ Upgrade => 'WebSocket', Connection => 'Upgrade', 'Sec-WebSocket-Accept' => $h->header('Sec-WebSocket-Accept') ]]
				);

				my $stream = $writer->[0]->stream;
				
				$stream->configure(
					on_read => sub {
						my ( undef, $buffref, $closed ) = @_;

						my $framebuffer = $hs->build_frame;

						$framebuffer->append( $$buffref );

						while( defined( my $frame = $framebuffer->next ) ) {
							$self->{on_frame}->( $stream, $frame );
						}
						return 0;
					},
					on_closed => sub {
						$self->{on_closed}->( shift ) if exists $self->{on_closed};
					}
				);

				$self->{on_handshake}->( $stream ) if exists $self->{on_handshake};	
			};
		}
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

C<Plack::App::Net::Async::WebSocket> - serve WebSocket clients using C<IO::Async> over PSGI

=head1 SYNOPSIS

 # app.psgi

 use Plack::App::Net::Async::WebSocket;

 my $app = Plack::App::Net::Async::WebSocket->new(
	on_handshake => sub {
		my ( $websocket ) = @_;
		$websocket->sent_frame( 'Hello' );
	},
	on_frame => sub {
		my ( $websocket, $frame ) = @_;
		$websocket->send_frame( $frame ); # echo
	},
	on_closed => sub {
		my ( $websocket ) = @_;
	}
 )->to_app;


 # using Plack::Builder

 use Plack::Builder;
 use Plack::App::Net::Async::WebSocket;

 builder {
	mount '/websocket' => Plack::App::Net::Async::WebSocket->new(
	       	on_frame => sub {
                	my ( $websocket, $frame ) = @_;
	                $websocket->send_frame( $frame ); # echo
        	},
 	);
 };
 

=head1 DESCRIPTION

This subclass of L<Plack::Component> accepts WebSocket connections. When a
new connection arrives it will perform an initial handshake and take control
over existing connection.

=head1 PARAMETERS

The following named parameters may be passed to C<new>:

=over 8

=item on_handshake => CODE

A CODE reference for when a new connection has been handshaked.
This parameter is optional

=item on_frame => CODE

A CODE reference for when a frame is received

=item on_close => CODE

This parameter is optional

=item on_error => CODE

This parameter is optional

=back

=head1 METHODS

=cut

=head2 $client->send_frame( @args )

Sends a frame to the peer containing the given string. The arguments 
are passed to L<Protocol::WebSocket::Frame>'s C<new> method.

=head1 SEE ALSO

=over 8

=item *

L<Net::Async::WebSocket> - WebSocket server using L<IO::Async>

=item *

L<Plack::Handler::Net::Async::HTTP::Server> - HTTP handler for Plack using L<Net::Async::HTTP::Server>

=back

=head1 AUTHOR

Paweł Feruś <null@mindc.net>

=cut
