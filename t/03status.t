use strict;
use warnings;
use Test::More tests => 4;
use Apache::ServerStatus;

my $content = <<EOT;
<dl><dt>Server Version: Apache/2.0.54 (Debian GNU/Linux) mod_ssl/2.0.54 OpenSSL/0.9.7e</dt>
<dt>Server Built: Jul 28 2006 09:04:55
</dt></dl><hr /><dl>
<dt>Current Time: Saturday, 10-Mar-2007 15:34:42 CET</dt>
<dt>Restart Time: Tuesday, 06-Mar-2007 19:09:18 CET</dt>
<dt>Parent Server Generation: 1</dt>
<dt>Server uptime:  3 days 20 hours 25 minutes 24 seconds</dt>
<dt>2 requests currently being processed, 7 idle workers</dt>
</dl><pre>_SRWKDCLGI.
_SRWKDCLGI.
</pre>
EOT

my $apss = new Apache::ServerStatus;
my ($p, $r, $i, $rest) =
   $content =~ $apss->{rx}->{2};

ok($p == 1, "parents");
ok($r == 2, "requests");
ok($i == 7, "idles");
ok($rest, "rest");
