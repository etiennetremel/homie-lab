#!/usr/bin/env sh
# This script is hacky but that was the only way to get a health check working
# with the available binaries from the nanomq container... PERL!

# build Base64 token
export token=$(printf "%s:%s" "$NANOMQ_HTTP_SERVER_USERNAME" "$NANOMQ_HTTP_SERVER_PASSWORD" | base64)

# Perl does the HTTP-over-TCP and exits 0 only on 2xx
perl -MIO::Socket::INET -e '
  my $host = "127.0.0.1";
  my $port = 8081;
  # connect or die (exit 1)
  my $s = IO::Socket::INET->new(
    PeerAddr => "$host:$port",
    Proto    => "tcp",
    Timeout  => 5
  ) or exit 1;

  # send request
  print $s
    "GET /api/v4/metrics HTTP/1.1\r\n",
    "Host: $host:$port\r\n",
    "Authorization: Basic $ENV{token}\r\n",
    "Connection: close\r\n\r\n";

  # read status
  my $line = <$s>;
  # match HTTP/1.x 2XX
  exit( $line && $line =~ m{^HTTP/\S+\s+2\d\d} ? 0 : 1 );
'
