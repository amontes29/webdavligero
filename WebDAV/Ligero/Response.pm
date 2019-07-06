package WebDAV::Ligero::Response;
use strict;

use XML::Ligero qw(xpath);
use WebDAV::Ligero::Field;
our $VERSION = 0.1;

use constant METHODS =>
 qw(COPY DELETE GET HEAD LOCK MKCOL MOVE OPTIONS POST PROPFIND PROPPATCH PUT TRACE UNLOCK);

sub new { bless {} => ref($_[0]) || $_[0] }
#+----------------+#
#| PUBLIC METHODS |#
#+----------------+#
sub populate{
  my $self = shift;
  $self->request(shift) or return
  my $method = $self->method = $self->request->method;
  return unless $self->can($method);
  $self->$method;
}


sub toString{
}

#+----------------+#
#| WEBDAV METHODS |#
#+----------------+#
sub PROPFIND{
  my $self = shift;
  #select all properties
  my %prop = qw(getcontentlanguage 1 getcontentlength 1 
   getcontenttype 1 getetag 1 getlastmodified 1 resourcetype 1);
  if(my $payload = $self->request->payload){
    my $xpath = xpath $payload or return;
    local $_ = shift @$xpath or return;
    return unless m!^/([^:/[]+:)?([^:/[]+)!;
    my ($prefix,$method) = ($1||'',$2);
    return unless 'PROPFIND' eq uc $method;
    $_ = shift @$xpath or return;
    s!/$prefix$method/$prefix(prop|allprop|propname)!! or return;
    my $type = $1;
    if($type eq 'prop'){
      $_ = 0 for values %prop;
      $_ = shift @$xpath or return;
      while(s!/$prefix$method/${prefix}prop/$prefix([^:/[]+)!!){
        $prop{$1} = 1 if exists $prop{$1}}}}
  my $uri = $self->request->uri;
  #depth 0|1|infinity   if omitted then infinity
  local $_ = ''; #manage dead properties?
  foreach my $key (grep $prop{$_}, keys %prop){
    my $val;
    if   ( $key eq 'getcontentlanguage' ){ $val = 'en'                            }
    elsif( $key eq 'resourcetype'       ){ $val = ''                              }
    elsif( $key eq 'getetag'            ){ $val = '"'.int(rand 100000).'"'        }
    elsif( $key eq 'getlastmodified'    ){ $val = 'Sun, 06 Nov 1994 08:49:37 GMT' }
    elsif( $key eq 'getcontenttype'     ){ $val = 'text/plain'                    }
    elsif( $key eq 'getcontentlength'   ){ $val = int rand 100000                 }
    else                                 { $val = ''                              }
    my $val = $prop{$key};
    $_ .= defined $val && length $val ? "<$key>$val</$key>$/" : "\t\t\t\t<$key/>$/";
  }
}

#+-------------------+#
#| PUBLIC PROPERTIES |#
#+-------------------+#
sub request{
  my $self = shift;
  $$self{_request} = shift if $_[0] && ref $_[0] eq 'WebDAV::Ligero::Request';
  $$self{_request};
}
sub error : lvalue {
  my $self = shift;
  $$self{_error} = shift if $#_ > -1;
  $$self{_error};
}
sub method : lvalue {
  my $self = shift;
  $$self{_method} = shift if $#_ > -1;
  $$self{_method};
}

