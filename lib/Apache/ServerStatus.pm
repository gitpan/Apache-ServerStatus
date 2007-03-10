=head1 NAME

Apache::ServerStatus - Simple module to parse apache's server-status.

=head1 SYNOPSIS

    use Apache::ServerStatus;

    my $apss = new Apache::ServerStatus;

    my $stat = $apss->get(request => 'http://localhost/server-status')
       or die $apss->errstr();

=head1 DESCRIPTION

This module parses the content of apache's server-status and countes the
current status by each process. It works nicely with apache versions 1.3
and 2.x.

=head1 METHODS

=head2 new()

Call C<new()> to create a new server status object.

=head2 get()

Call C<get()> to get the parsed server status. This method returns a hash reference with
the counted status. There are diffenrent keys that contains the following counts:

   r    Requests currenty being processed
   i    Idle workers
   p    Parents
   _    Waiting for Connection
   S    Starting up
   R    Reading Request
   W    Sending Reply
   K    Keepalive (read)
   D    DNS Lookup
   C    Closing connection
   L    Logging
   G    Gracefully finishing
   I    Idle cleanup of worker
   .    Open slot with no current process

=head2 errstr()

C<errstr()> contains the error string if the requests fails.

=head1 OPTIONS

You have to set all options by the call of C<get()>.

There are only two options: C<request> and C<timeout>.

Set C<request> with the complete uri like C<http://localhost/server-status>.
There is only http supported, not https or other protocols.

Set C<timeout> to define the time in seconds to abort the request if there is no
response. The default is set to 180 secondes if the options isn't set.

=head1 EXAMPLE CONFIGURATION FOR APACHE

This is just an example to activate the handler server-status for localhost.

    <Location /server-status>
        SetHandler server-status
        Order Deny,Allow
        Deny from all
        Allow from localhost
    </Location>

=head1 DEPENDENCIES

    Carp
    LWP::UserAgent
    Params::Validate

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Apache::ServerStatus;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp qw(croak);
use LWP::UserAgent;
use Params::Validate;

$__PACKAGE__::TIMEOUT = 180;

sub new {
   my $class = shift;
   my %self  = ();

   $self{rx}{1} = qr{
      Parent\s+Server\s+Generation:\s+(\d+)\s+<br>.+
      (\d+)\s+requests\s+currently\s+being\s+processed,\s+(\d+)\s+idle\s+servers.+?
      <PRE>([_SRWKDCLGI.\n]+)
      </PRE>
   }xs;

   $self{rx}{2} = qr{
      <dt>Parent\s+Server\s+Generation:\s+(\d+)</dt>.+
      <dt>(\d+)\s+requests\s+currently\s+being\s+processed,\s+(\d+)\s+idle\s+workers</dt>.+
      </dl><pre>([_SRWKDCLGI.\n]+)
      </pre>
   }xs;

   $self{ua} = LWP::UserAgent->new();
   $self{ua}->protocols_allowed(['http']);

   return bless \%self, $class;
}

sub get {
   my $self     = shift;
   my $regexes  = $self->{rx};
   my %data     = map { $_ => 0 } qw(r i p _ S R W K D C L G I .);

   my %opts     = Params::Validate::validate(@_, {
      request => {
         type => Params::Validate::SCALAR,
         regex => qr{^http://.+},
      },
      timeout => {
         type => Params::Validate::SCALAR,
         regex => qr/^\d+$/,
         default => $__PACKAGE__::TIMEOUT,
      },
   });

   $self->{ua}->timeout($opts{timeout});
   my $response = $self->{ua}->get($opts{request});

   return $self->_raise_error($response->status_line())
      unless $response->is_success();

   my $content   = $response->content();
   my ($version) = $content =~ m{Server\s+Version:\s+Apache/(\d)};
   my $rest      = ();

   return $self->_raise_error("apache/$version is not supported")
      unless exists $regexes->{$version};

   ($data{p}, $data{r}, $data{i}, $rest) =
      $content =~ $regexes->{$version};

   $rest =~ s/\n//g;
   $data{$_}++ for (split //, $rest);

   return \%data;
}

sub errstr { return $__PACKAGE__::errstr }

#
# private stuff
#

sub _raise_error {
   my $self   = shift;
   my $class  = ref($self);
   my $errstr = shift;
   $__PACKAGE__::errstr = $errstr || '';
   return undef;
}

1;
