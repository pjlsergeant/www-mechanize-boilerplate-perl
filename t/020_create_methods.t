#!perl

use strict;
use warnings;

use Test::More;
use Test::MockObject;
use WWW::Mechanize::Boilerplate;

# Happy-path tests for method creation

# Set up to capture all diagnostic output
our @notes;
{
    no warnings qw/redefine once/;
    *WWW::Mechanize::Boilerplate::indent_note = sub {
        my ( $class, $note ) = @_;
        push( @notes, $note );
    }
}

# Set up a fake mech, and instantiate a new client
my $mech = Test::MockObject->new();
$mech->set_isa('WWW::Mechanize');
my $client = WWW::Mechanize::Boilerplate->new({ mech => $mech });
my $uri = Test::MockObject->new();
$uri->set_always( path_query => '/foo/bar' );
$mech->set_always( uri => $uri );

# Capture stuff sent to various mechanize methods
our @mech_actions;
sub add_action { my $type = shift; my $class = shift; push( @mech_actions, [$type, @_] ) }
$mech->mock( get     => sub { add_action('get', @_) } );
$mech->mock( success => sub { add_action('success', @_); return 1 } );

# Set up a simple fetch method
$client->create_fetch_method(
    method_name      => 'new_fetch',
    page_description => 'some page',
    page_url         => 'http://foo/bar',
);

# Check it showed up and works
{
    local @notes;
    local @mech_actions;

    $client->new_fetch();

    # Check diagnostic outputs
    is_deeply(
        \@notes,
        [split(/\n/,
"->new_fetch()
Retrieving the some page: [http://foo/bar]
Retrieved the some page : [/foo/bar]
is_success() returned true"
        )],
        "Output as expected from new_fetch"
    );

    # Check action outputs
    is_deeply(
        \@mech_actions,
        [
            [ get => 'http://foo/bar' ],
            [ 'success' ]
        ],
        "Actions as expected from new_fetch"
    );
}