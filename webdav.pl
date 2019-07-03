#/usr/bin/perl -w
use strict;

package myWebDAV;

use base qw(Net::Server);
use WebDAV::Ligero::Request;

sub process_request{
  my $req = WebDAV::Ligero::Request->new;
  $req->parse;
  use Data::Dumper;
  print Dumper $req;
  #print $webdav->response_toString;
}


package main;

my $srv = myWebDAV->new;
$srv->run(port=>shift||1234);
