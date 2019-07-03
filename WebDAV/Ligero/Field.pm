package WebDAV::Ligero::Field;

use strict;

our $VERSION = 0.1;

sub new{
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my $self = bless {} => $class;
  return unless defined $self->key(shift);
  return unless defined $self->value(shift);
  $self;
}

sub key{
  my $self = shift;
  $$self{_key} = shift if defined $_[0] && length $_[0];
  $$self{_key};
}

sub value{
  my $self = shift;
  $$self{_value} = shift if defined $_[0] && length $_[0];
  $$self{_value};
}

1
