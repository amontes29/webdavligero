package WebDAV::Ligero::Request;
use strict;

use IO::Read qw(ioread);
use WebDAV::Ligero::Field;
our $VERSION = 0.13;

use constant METHODS =>
 qw(COPY DELETE GET HEAD LOCK MKCOL MOVE OPTIONS POST PROPFIND PROPPATCH PUT TRACE UNLOCK);
our ($read_buf, $max_header, $max_content);

sub new { bless {} => ref($_[0]) || $_[0] }
#+----------------+#
#| PUBLIC METHODS |#
#+----------------+#
sub parse{
  my $self = shift;
  return unless $self->initialize && $self->_fetch_firstline && $self->_fetch_fields;
  if($self->_requires_payload){
    return unless $self->_fetch_content;
    $self->payload = $self->_buffer;
    $self->_buffer = undef} 1
}
sub initialize{
  local $_ = my $self = shift;
  return 1 if $$self{_initialized};
  ($self->_firstline,$self->_buffer) = ('','');
  $_->read_buf || $_->read_buf($read_buf) || $_->read_buf(4096);
  $_->max_header || $_->max_header($max_header) || $_->max_header(1024);
  $_->max_content || $_->max_content($max_content) || $_->max_content(4096*1024);
  $$self{_initialized} = 1;
}

#+-------------------+#
#| PUBLIC PROPERTIES |#
#+-------------------+#
sub read_buf{
  my $self = shift;
  $$self{_read_buf} = shift if $_[0] && $_[0] =~ /^\d+$/;
  $$self{_read_buf};
}
sub max_header{
  my $self = shift;
  $$self{_max_header} = shift if $_[0] && $_[0] =~ /^\d+$/;
  $$self{_max_header};
}
sub max_content{
  my $self = shift;
  $$self{_max_content} = shift if $_[0] && $_[0] =~ /^\d+$/;
  $$self{_max_content};
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
sub uri : lvalue {
  my $self = shift;
  $$self{_uri} = shift if $#_ > -1;
  $$self{_uri};
}
sub field{
  my $self = shift;
  local $_ = shift;
  return if !defined || (ref && ref ne 'WebDAV::Ligero::Field');
  return $$self{_fields}{lc $_->key} = $_ if ref;
  $$self{_fields}{lc $_};
}
sub payload : lvalue{
  my $self = shift;
  $$self{_payload} = shift if $#_ > -1;
  $$self{_payload};
}

#+-----------------+#
#| PRIVATE METHODS |#
#+-----------------+#
sub _fetch_firstline{
  my $self = shift;
  $$self{_initialized} = 0;
  local $_ = ioread(rmax=>$self->max_header);
  $self->error($$_) and return if defined && ref eq 'SCALAR';
  $self->error('method and/or uri') and return unless s!^(([^ ]+) ([^ ]+) [^ ]+\015?\012)!!;
  my ($firstline,$method,$uri) = ($1,$2,$3);
  $self->error('max_header') and return unless $self->max_header >= length $firstline;
  $self->error("method '$method' not supported") and return unless $self->method($method);
  $self->error("uri $uri") and return unless $self->uri($uri);
  ($self->_firstline,$self->_buffer) = ($firstline,$_); 1
}
sub _fetch_fields{
  my $self = shift;
  local $_ = $self->_buffer;
  my $rmax = $self->max_header-length($self->_firstline)-length;
  while(!/\015?\012\015?\012/ && $rmax > 0 && !eof STDIN){
    my $line = ioread(rmax=>$rmax);
    $self->error($$line) and return if defined $line && ref $line eq 'SCALAR';
    $rmax -= length $line;
    $self->_buffer = $_ .= $line}
  $self->error('max_header') and return if !s/^(.*?\015?\012)\015?\012//s && ($rmax<=0 || eof);
  $self->_buffer = $_;
  my %f = $1 =~ / *([^:]+?) *: *(.+?) *\015?\012/g;
  $self->error('no fields found') and return unless keys %f;
  foreach(keys %f){
    my $field = WebDAV::Ligero::Field->new($_,$f{$_});
    $self->error("field object: $_ => $f{$_}") and return unless $field;
    $self->error("field: $_ => $f{$_}") and return unless $self->field($field)} 1
}
sub _fetch_content{
  my $self = shift;
  my $length = $self->field('content-length');
  $length = $length && $length->value && $length->value =~ /^\d+$/ ? $length->value : 0;
  $self->error('no content-length') and return unless $length;
  $self->error('max content-length') and return unless $length <= $self->max_content;
  my $rmax = $length-length $self->_buffer;
  $self->error('content-length mismatch') and return unless $rmax >= 0;
  my $rbuf = $self->read_buf > $rmax ? $rmax : $self->read_buf;
  my $content = ioread(rbytes=>1, rmax=>$rmax, rbuf=>$rbuf) if $rmax;
  $self->error($$content) and return if defined $content && ref $content eq 'SCALAR';
  $self->_buffer .= $content if defined $content && length $content;
  $self->error('content-length overflow') and return if $length < length $self->_buffer;
  $self->error('content incomplete') and return if $length > length $self->_buffer; 1
}

#+--------------------+#
#| PRIVATE PROPERTIES |#
#+--------------------+#
sub _firstline : lvalue{
  my $self = shift;
  $$self{_firstline} = shift if $#_ > -1;
  $$self{_firstline};
}
sub _buffer : lvalue{
  my $self = shift;
  $$self{_buffer} = shift if $#_ > -1;
  $$self{_buffer};
}
sub _requires_payload{
  my $self = shift;
  local $_ = $self->method;
  return unless defined;
  if($_ eq 'PROPFIND'){
    $self->field('content-length') ? 1 : 0;
  }else{
    /^(?:PUT|POST)$/ ? 1 : 0;
  }
}

1;
