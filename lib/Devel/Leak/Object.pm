
package Devel::Leak::Object;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.02;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw (track bless status);
	%EXPORT_TAGS = ();
}


########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

Devel::Leak::Object - Detect leaks of objects 

=head1 SYNOPSIS

  use Devel::Leak::Object;
  my $obj = Foo::Bar->new;
  Devel::Leak::Object::track($obj);


=head1 DESCRIPTION

This module provides tracking of objects, against memory leaks. At a simple
level, object tracking can be enabled on a per object basis. Any objects
thus tracked are remembered until DESTROYed; details of any objects left
are printed out to stderr. 

  use Devel::Leak::Object qw(GLOBAL_bless);

This form overloads B<bless> to track construction and destruction of all
objects. As an alternative, by importing bless, you can just track the
objects of the caller code that is doing the use.

=head1 BUGS

Please report bugs to http://rt.cpan.org

=head1 AUTHOR

	Ivor Williams
	ivorw-devel-leak-object@xemaps.com
	
=head1 COPYRIGHT

Copyright (C) 2004 Ivor Williams.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

use Carp;

our %objcount;
our %tracked;
our %destroy_orig;

use Data::Dumper;

sub import {
    for my $i (0..$#_) {
        next unless $_[$i] =~ /^GLOBAL_(.*)/;
        my $sym = $1;
        splice @_,$i,1;
        no strict 'refs';
        *{'CORE::GLOBAL::'.$sym} = \&{$sym};
    }
    goto &Exporter::import;
}
                    
sub bless {
    my ($ref,$pkg) = @_;
    my $obj = CORE::bless($ref,$pkg);
    Devel::Leak::Object::track($obj);
    $obj;
};

sub track
{
	my $obj = shift;

	my ($class,$type,$addr) = "$obj" =~ /^
		((?:\w|\:\:)+)			# Stringification has pkg name
		=(ARRAY|HASH|SCALAR|GLOB|CODE)  # type
		\((0x[0-9a-f]+)\)		# and address
		/x or carp "Not passed an object";
	if (exists $tracked{$addr}) {		# rebless of tracked object
	    $objcount{$tracked{$addr}}--;
	}
	$tracked{$addr} = $class;
	if (!exists $objcount{$class}) {
	    no strict 'refs';
	    if ((exists ${$class.'::'}{DESTROY}) && 
	            *{$class.'::DESTROY'}{CODE}) {
	        $destroy_orig{$class} = \&{$class.'::DESTROY'};
	    }
	    *{$class.'::DESTROY'} = \&_DESTROY_stub;
	    ${$class.'::DESTROY_stubbed'} = 1;
	}
	$objcount{$class}++;
}

sub status {
	print "Status of all classes:\n";
	for (sort keys %objcount) {
		printf "%-40s %d\n", $_, $objcount{$_};
	}
}

sub _DESTROY_stub {
	my ($obj) = @_;
	my ($class,$type,$addr) = "$obj" =~ /^
		((?:\w|\:\:)+)			# Stringification has pkg name
		=(ARRAY|HASH|SCALAR|GLOB|CODE)  # type
		\((0x[0-9a-f]+)\)             # and address
		/x or carp "Not passed an object";
	if (exists($objcount{$class})) {
	    $objcount{$class}--;
	    warn "Object count for $class negative ($objcount{$class})\n"
	        if $objcount{$class} < 0;
	    warn "Object not tracked" unless exists $tracked{$addr};
	    delete $tracked{$addr};
	}
	goto &{$destroy_orig{$class}} if exists $destroy_orig{$class};
	
        no strict 'refs';

	my @inherited = @{$class.'::ISA'} ;

	while (@inherited) {
	    my $superclass = shift @inherited;
	    unshift @inherited, @{$superclass.'::ISA'}
	       if exists ${$superclass.'::'}{ISA};
	    goto &{$destroy_orig{$superclass}}  
	       if exists $destroy_orig{$superclass};
	    goto &{$superclass.'::DESTROY'}
	       if exists(${$superclass.'::'}{DESTROY}) &&
	           *{$superclass.'::DESTROY'}{CODE} &&
	           !exists ${$superclass.'::'}{DESTROY_stubbed};
	}
}

END {
	status();
}

1; #this line is important and will help the module return a true value
__END__

