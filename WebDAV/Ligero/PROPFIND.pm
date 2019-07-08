package WebDAV::Ligero::PROPFIND;
use strict;

use XML::Ligero qw(xpath);
our $VERSION = 0.11;

use constant PROP_LIVE =>
 qw(getcontentlanguage getcontentlength getcontenttype getetag getlastmodified resourcetype);

sub WebDAV::Ligero::Response::PROPFIND{
  my $self = shift;
  my ($propfind_method,%prop_req) = _PROPFIND_method_payload($self->request->payload);
  #my ($root,$depth) = ($self->root,$self->request->field('depth'));
  my ($root,$depth) = ('/tmp/webdav',$self->request->field('depth'));
  $depth = 1 if !defined $depth || $depth !~ /^[01]$/;
  my (@uri,%resources) = ($self->request->uri);
  my $asctime = qr/(\w+)\s+(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+(\d+)/;
  while(my $uri = shift @uri){
    $uri =~ s!//!/!g;
    my $resource = {uri=>$uri, prop=>{}, status=>'HTTP/1.1 XXX error aqui...'};
    $resources{$uri} = $resource;
    my $path = "$root/$uri"; #root method missing
    $path =~ s!//!/!g;
    if(-e $path && -r _){
      my ($isDir,@s) = (-d _,stat _);
      $$resource{status} = 'HTTP/1.1 200 OK';
      if($propfind_method eq 'propname'){
        $$resource{prop}{$_} = '' for keys %prop_req;
      }else{ #rfc1123date: 'Sun, 06 Nov 1994 08:49:37 GMT'   asctime: Sun Jul  7 19:16:22 2019
        foreach my $k (grep $prop_req{$_}, keys %prop_req){ my $v;
          if   ( $k eq 'getlastmodified'    ){ 
           gmtime($s[9])=~/$asctime/;my$d=1==length$3?"0$3":$3;$v="$1, $d $2 $5 $4 GMT"}
          elsif( $k eq 'resourcetype'       ){ $v = $isDir ? '<collection/>' : ''      }
          elsif( $k eq 'getcontentlanguage' ){ $v = 'en'                               }
          elsif( $k eq 'getetag'            ){ $v = '"'.$s[1].'"'                      }
          elsif( $k eq 'getcontenttype'     ){ $v = ''                                 }
          elsif( $k eq 'getcontentlength'   ){ $v = $s[7]                              }
          else                               { $v = undef                              }
          $$resource{prop}{$k} = $v if defined $v}}
      if($depth){
        $depth = 0;
        if($isDir){
          opendir my $dh,$path or die "Cannot open dir $path: $!$/";
          push @uri, map "$uri/$_", grep !/^\.{1,2}$/, readdir $dh;
          closedir $dh or die "Cannot close dir $path: $!$/"}}}}
  my $xml = qq(<?xml version="1.0" encoding="utf-8" ?>$/ <multistatus xmlns="DAV:">$/);
  foreach(values %resources){
    my ($uri,$status,$prop) = @$_{qw(uri status prop)};
    $xml .= "  <response>$/   <href>$uri</href>$/   <propstat>$/    <prop>$/";
    while(my ($k,$v) = each %$prop){
      $xml .= length $v ? "     <$k>$v</$k>$/":"     <$k/>$/"}
    $xml .= "    </prop>$/    <status>$status</status>$/   </propstat>$/  </response>$/"}
  $xml .= " </multistatus>$/"; $xml
}

#sub WebDAV::Ligero::Response::_PROPFIND_method_payload{
sub _PROPFIND_method_payload{
  my (%prop,$prefix,$method) = map {$_,1} PROP_LIVE;
  if(my $payload = shift){
    my $xpath = xpath $payload or return;#enhance error description/handling
    local $_ = shift @$xpath or return;
    return unless m!^/([^:/[]+:)?([^:/[]+)!;
    ($prefix,$method) = ($1||'',$2);
    return unless 'PROPFIND' eq uc $method;
    $_ = shift @$xpath or return;
    m!/$prefix$method/$prefix(prop|allprop|propname)! or return;
    if($1 eq 'prop'){
      $_ = 0 for values %prop;
      while( ($_ = shift @$xpath) && m!/$prefix$method/${prefix}prop/$prefix([^:/[]+)! ){
        $prop{$1} = 1 if exists $prop{$1}}}} $method||'allprop',%prop
}

1;
