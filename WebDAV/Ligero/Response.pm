package WebDAV::Ligero::Response;
use strict;

use WebDAV::Ligero::PROPFIND;
our $VERSION = 0.11;

use constant METHODS =>
 qw(COPY DELETE GET HEAD LOCK MKCOL MOVE OPTIONS POST PROPFIND PROPPATCH PUT TRACE UNLOCK);

sub new { bless {} => ref($_[0]) || $_[0] }
#+----------------+#
#| PUBLIC METHODS |#
#+----------------+#
sub populate{
  my $self = shift;
  $self->request(shift) or return;
  my $method = $self->request->method or return;
  return unless $self->can($method);
  $self->header(  "HTTP/1.1 207 Multi-Status$/".
                qq!Content-Type: application/xml; charset="utf-8"$/!.
                  'Content-Length: '.length($self->content($self->$method)).$/);1
}
sub string{
  my $self = shift;
  $self->header.$/.$self->content;
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
sub header{
  my $self = shift;
  $$self{_header} = shift if $#_ > -1;
  $$self{_header} || '';
}
sub content{
  my $self = shift;
  $$self{_content} = shift if $#_ > -1;
  $$self{_content} || '';
}

1;
