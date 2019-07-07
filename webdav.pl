#/usr/bin/perl -w
use strict;

package myWebDAV;

use base qw(Net::Server);
use WebDAV::Ligero::Request;
use WebDAV::Ligero::Response;

sub process_request{
  my $req = WebDAV::Ligero::Request->new;
  $req->parse;
  my $res = WebDAV::Ligero::Response->new;
  $res->populate($req);
  print $res->string;
}


package main;

my $srv = myWebDAV->new;
$srv->run(port=>shift||1234);
