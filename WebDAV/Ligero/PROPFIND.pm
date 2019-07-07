package WebDAV::Ligero::PROPFIND;
use strict;

use XML::Ligero qw(xpath);
our $VERSION = 0.1;

use constant PROP_LIVE =>
 qw(getcontentlanguage getcontentlength getcontenttype getetag getlastmodified resourcetype);

sub WebDAV::Ligero::Response::PROPFIND{
  my $self = shift;
  my (%prop,$prefix,$method) = map {$_,1} PROP_LIVE;
  if(my $payload = $self->request->payload){
    my $xpath = xpath $payload or return;
    local $_ = shift @$xpath or return;
    return unless m!^/([^:/[]+:)?([^:/[]+)!;
    ($prefix,$method) = ($1||'',$2);
    return unless 'PROPFIND' eq uc $method;
    $_ = shift @$xpath or return;
    m!/$prefix$method/$prefix(prop|allprop|propname)! or return;
    if($1 eq 'prop'){
      $_ = 0 for values %prop;
      while( ($_ = shift @$xpath) && m!/$prefix$method/${prefix}prop/$prefix([^:/[]+)! ){
        $prop{$1} = 1 if exists $prop{$1}}}}
  my $depth = $self->request->field('depth');
  $depth = 1 if !defined $depth || $depth !~ /^[01]$/;
  my @response = ($self->request->uri);
  local $_ = qq(<?xml version="1.0" encoding="utf-8" ?>$/ <multistatus xmlns="DAV:">$/);
  foreach my $uri (@response){
    my $status = 'HTTP/1.1 200 OK';
    $_ .= "  <response>$/   <href>$uri</href>$/   <propstat>$/    <prop>$/";
    if($method eq 'propname'){
      $_ .= "     <$_/>$/" for keys %prop;
    }else{
      foreach my $key (grep $prop{$_}, keys %prop){ my $val;
        if   ( $key eq 'getcontentlanguage' ){ $val = 'en'                            }
        elsif( $key eq 'resourcetype'       ){ $val = ''                              }
        elsif( $key eq 'getetag'            ){ $val = '"'.int(rand 100000).'"'        }
        elsif( $key eq 'getlastmodified'    ){ $val = 'Sun, 06 Nov 1994 08:49:37 GMT' }
        elsif( $key eq 'getcontenttype'     ){ $val = 'text/plain'                    }
        elsif( $key eq 'getcontentlength'   ){ $val = int rand 100000                 }
        else                                 { $val = ''                              }
        $_ .= defined$val && length$val ? "     <$key>$val</$key>$/":"     <$key/>$/"  }}
    $_ .= "    </prop>$/    <status>$status</status>$/   </propstat>$/  </response>$/"   }
  $_ .= " </multistatus>$/";
}

1;
