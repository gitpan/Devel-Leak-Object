# -*- perl -*-

# t/001_basic.t - Basic tests

use Test::More tests => 7;

#01
BEGIN { use_ok( 'Devel::Leak::Object' ); }

my $foo = bless {}, 'Foo::Bar';

#02
isa_ok($foo, 'Foo::Bar', "Before the tests");

Devel::Leak::Object::track($foo);

#03
is ($Devel::Leak::Object::objcount{Foo::Bar},1,'# objects ($foo)');

my $buzz = bless [], 'Foo::Bar';
Devel::Leak::Object::track($buzz);

#04
is ($Devel::Leak::Object::objcount{Foo::Bar},2,'# objects ($foo,$buzz)');

undef $foo;

#05
is ($Devel::Leak::Object::objcount{Foo::Bar},1,'# objects ($buzz)');

undef $buzz;

#06
is ($Devel::Leak::Object::objcount{Foo::Bar},0,'no objects left');

#07
is (scalar(keys %Devel::Leak::Object::tracked), 0, 'Nothing still tracked');
