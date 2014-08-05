package WWW::Mechanize::Boilerplate;

use strict;
use warnings;

use Carp qw(croak shortmess);
use Data::Dump qw(dump);
use Moose;

has 'mech' => ( isa => 'WWW::Mechanize', is => 'rw', default => sub {
    require WWW::Mechanize;
    return WWW::Mechanize->new();
} );

=head1 NAME

WWW::Mechanize::Boilerplate - Compose Mechanize macros from specifications

=head1 DESCRIPTION

Create WWW::Mechanize `macros` with appropriate boiler plate

=head1 SYNOPSIS

I<Create a subclass to hold your methods>

 package Test::My::Company::Client;
 use base 'WWW::Mechanize::Boilerplate';

 __PACKAGE__->create_fetch_method(
    method_name      => 'delorean__configuration',
    page_description => 'configuration page for the Delorean',
    page_url         => '/delorean/configuration'
 );

 __PACKAGE__->create_form_method(
    method_name       => 'delorean__configuration__flux_capacitor',
    form_name         => 'form-flux-capacitor'
    form_description  => 'recalibration form',
    assert_location   => qr!^/delorean/configuration/!,
    transform_fields  => sub {
        my ( $self, $units, $value ) = @_;
        return {
            value => $value,
            units => $units,
            understand_risks => 'confirmed'
        };
    },
 );

I<Then in your test script>

 my $client = Test::My::Company::Client->new();

 $client->delorean__configuration()
        ->delorean__configuration__flux_capacitory( jigawatts => 10_000 );

I<Pretty debugging output>

 #   ->delorean__configuration
 #       Retrieving the configuration page for the Delorean
 #       URL /delorean/configuration retrieved successfully via HTTP
 #       Retrieved the configuration page for the Delorean
 #       No status message shown
 #   ->delorean__configuration__flux_capacitor( 'jigawatts', 10_000 )
 #       URL [/delorean/configuration] matched assertion
 #       Searching for the recalibration form
 #       Submitting recalibration form
 #       URL /delorean/configuration?updated=1 retrieved successfully via HTTP
 #       No status message shown

We document the method-creation methods in L<METHOD CREATION METHODS> below, and
we document the interface in L<INTERFACE>.

=head1 BACKGROUND

=head2 The Application

In the beginning, there was 'the application'. The application had 230 Apache
handlers, each capturing one or more HTTP request. These HTTP requests often had
subtly different CGI parameters, some only made sense when you were already on
certain pages, and all of them, eventually, needed accessing from automated
functional tests.

The tests didn't want to care about the underlying HTTP mechanism, or even the
underlying HTML. The test just wanted to be able to say:

 $mech->flux_capacitor__submit_recallibration({
    jigawatts => 10_000
 });

So why not just use L<WWW::Mechanize>? That's what it's for, right? You can
simply say:

 $mech->submit_form( with_fields => {
    value => 10_000,
    units => 'jigawatts',
    understand_risks => 'confirmed'
 });

And this works just fine for a single test on the Flux Capacitor page.

=head2 It's a Trap!

But clearly this is a trap. Because as we're all adults, actually, we want to
check we're on the right page first, because it'll be super confusing otherwise
if the former method left us on the wrong page, and we're trying to work out
why we're not writing to the database.

And we also want to add a whole bunch of optional diagnostic output to help the
poor developer trying to read the output on Jenkins from where everything
stopped working.

And actually, the form has two buttons I<for historical reasons>, one of which
should be used for over 1,000 I<jigawtts>, and one for under. So you need to
add the form selection code in too.

Did I mention 14 different test scripts use this page and need to submit the
jigawatt form, and the team that sits across the office from you are making
noises about changing the form structure in the next iteration?

=head2 Abstraction

All of this is pretty easily solved. You write a nice method against your
L<WWW::Mechanize> subclass called 'submit_the_flux_capacitor_form', and the
problem is solved.

For that form, anyway. On that handler.

Now you just need to code up the next 400 possible HTTP actions your test might
want to take, and you're home clear...

B<And that's the problem this module solves, for us.> It allows you to very
easily create methods that generate HTTP requests, with useful boiler plate, and
most importantly, B<in data>.

Here a simple example for creating a method for getting to the jigawat form:

 ->create_fetch_method(
    method_name      => 'delorean__configuration',
    page_description => 'configuration page for the Delorean',
    page_url         => '/delorean/configuration'
 );

And a more complicated one for a method for submitting it:

 ->create_form_method(

    # Name of the method we'll create
    method_name       => 'delorean__configuration__flux_capacitor',

    # Name of the form-element on the target page
    form_name         => 'form-flux-capacitor'

    # Human-readable description of the form we're targetting
    form_description  => 'recalibration form',

    # Check we're on the right page, by URI
    assert_location   => qr!^/delorean/configuration/!,

    # A code-ref to transform the user's arguments to this method to something
    # suitable for passing to Mechanize.
    transform_fields  => sub {
        my ( $self, $units, $value ) = @_;
        return {
            value => $value,
            units => $units,
            understand_risks => 'confirmed'
        };
    },
 );

And you'd use these as:

 $client->delorean__configuration
      ->delorean__configuration__flux_capacitor( jigawatts => 10_000 );

Optionally seeing the following output, via L<Test::More>'s C<note()>.

 #   ->delorean__configuration
 #       Retrieving the configuration page for the Delorean
 #       URL /delorean/configuration retrieved successfully via HTTP
 #       Retrieved the configuration page for the Delorean
 #       No status message shown
 #   ->delorean__configuration__flux_capacitor( 'jigawatts', 10_000 )
 #       URL [/delorean/configuration] matched assertion
 #       Searching for the recalibration form
 #       Submitting recalibration form
 #       URL /delorean/configuration?updated=1 retrieved successfully via HTTP
 #       No status message shown

=head1 INSTANTIATION

=head2 new

 ->new();
 ->new({ mech => WWW::Mechanize->new() });

Accepts a hashref containing - for now - a single argument of C<mech>
which should be a WWW::Mechanize subclass. If you don't provide one,
we'll create a default one.

=head1 METHOD CREATION METHODS

=head2 create_fetch_method

 ->create_fetch_method(
    method_name      => 'delorean__configuration',
    page_description => 'configuration page for the Delorean',
    page_url         => '/delorean/configuration?car_id=',
    required_param   => 'Car ID'
 );

Creates a method that retrieves a URL. Arguments:

B<Required:>

C<method_name> - name of the method to create

C<page_description> - what's the page called? Used for diagnostics

C<page_url> - the page to fetch

B<Optional:>

C<assert_location> - Argument to pass to C<assert_location()>

C<required_param> - If your URL needs a trailing atom to complete it, set
this to a true value. The user of the method will be required to provide an
argument, and it'll be named (in diagnostic output) to the value you assigned
it.

That means, in the value above, when you call the method, you also must provide
an argument:

 $framework->delorean__configuration( 1234 );

There will be a diagnostic method printed:

 # Car ID is [1234]

And the following URL will be retrieved:

 C</delorean/configuration?car_id=1234>

=cut

sub create_fetch_method {
    my ( $class, %args ) = @_;

    # This is a good place to check a user is using it correctly...
    $class->_auto_methods_check_params(\%args,
        {
            required => [qw/method_name page_description page_url/],
            optional => [qw/assert_location required_param/],
        });

    $class->meta->add_method(
        $args{'method_name'} => sub {
            my ( $self, $atom ) = @_;
            $self->show_method_name( $args{'method_name'}, $atom );

            # If we need a URL atom, insist that we have it
            croak("You must provide a $args{'required_param'}")
                if ( $args{'required_param'} && (! defined($atom) ) );

            # Check we're in the right place
            $self->assert_location( $args{'assert_location'} ) if
                defined $args{'assert_location'};

            # Create the URL
            my $target_url = $args{'page_url'};
            $target_url .= $atom if defined $atom;

            $self->indent_note(
                "Retrieving the $args{'page_description'}: [$target_url]", 1);

            # HTTP call
            $self->mech->get( $target_url );

            # Status update
            $self->indent_note(
                "Retrieved the $args{'page_description'} : [" .
                    $self->mech->uri->path_query . "]", 1);
            $self->note_status();
            return $self;
        }
    );
}


=head2 create_form_method

 ->create_form_method(
    method_name       => 'delorean__configuration__flux_capacitor',
    form_name         => 'form-flux-capacitor'
    form_description  => 'recalibration form',
    assert_location   => qr!^/delorean/configuration/!,
    transform_fields  => sub {
        my ( $self, $units, $value ) = @_;
        return {
            value => $value,
            units => $units,
            understand_risks => 'confirmed'
        };
    }
 );

Finds a form on a page, and submits it. Arguments:

B<Required:>

C<method_name> - name of the method to create

C<form_description> - the human-readable description of the form you're
submitting. You don't need to append the word 'form' to this.

C<assert_location> - Argument to pass to C<assert_location()>

C<form_*> - one of the form resolvers listed below

B<Optional:>

C<form_name> - the name attribute of the target form. Passed to
L<WWW::Mechanize>'s C<form_name()> method. You can pass in a coderef
here, which will get called just like C<transform_fields> and should
return a string. Instead of C<form_name> you can use C<form_id> or
C<form_button> to select forms by ID or button.

C<transform_fields> - a code-ref. Will receive $self and the methods arguments,
and expects you to return a hash-ref suitable for passing to L<WWW::Mechanize>'s
C<set_fields> method. This is a great place to put in default arguments, and
also a great place to use C<note()> to tell the test output reader what's going
on.

C<form_button> - argument to pass to L<WWW::Mechanize>'s C<submit_form> value
as C<button>. Used for specifying which button to use to submit a form. This is
a string of the button name. You can pass in a coderef here, which will get
called just like C<transform_fields> and should return a string.

=cut

my @form_resolvers = qw/form_name form_id form_number/;

sub create_form_method {
    my ( $class, %args ) = @_;

    # This is a good place to check a user is using it correctly...
    $class->_auto_methods_check_params(\%args,
        {
            required => [qw/
                method_name form_description assert_location
            /],
            optional => [@form_resolvers, qw/
                form_button transform_fields
            /],
        });

    $class->meta->add_method(

        $args{'method_name'} => sub {
            my ( $self, @user_options ) = @_;
            $self->show_method_name( $args{'method_name'}, @user_options );

            croak "You must define one of form_name, form_id or form_number."
                unless map { defined $args{$_} ? (1) : () } @form_resolvers;

            # Check we're in the right place
            $self->assert_location( $args{'assert_location'} )
                if defined $args{'assert_location'};

            my $transformed_fields = $args{'transform_fields'} ?
                $args{'transform_fields'}->( $self, @user_options ) : {};

            $self->indent_note("Searching for the $args{'form_description'} form", 1);

            # Attempt to find the right form
            for my $r ( @form_resolvers ) {
                next unless defined $args{$r};

                my $name = ref($args{$r}) eq 'CODE' ?
                    $args{$r}->( $self, @user_options ) :
                    $args{$r};
                my $form = $self->mech->$r( $name );

                unless ( $form ) {
                    croak "Couldn't find a form with $r [$name]";
                }

                last;
            }

            $self->mech->set_fields( %$transformed_fields );

            my $button = ref($args{'form_button'}) eq 'CODE' ?
                $args{'form_button'}->( $self, @user_options ) :
                $args{'form_button'};

            $self->indent_note("Submitting $args{'form_description'} form", 1);
            $self->mech->submit_form(
                fields => $transformed_fields,
                $button ? ( button => $button ) : ()
            );

            $self->note_status;
            return $self;
        }
    );
}

=head2 create_link_method

 ->create_link_method(
    method_name      => 'delorean__configuration__current_stats',
    link_description => 'Current Stats',
    find_link        => { text => 'View Current Stats' },
    assert_location  => '/delorean/configurations'
 );

Creates a method that finds a link on the current page and clicks it.

Arguments:

B<Required:>

C<method_name> - name of the method to create

C<link_description> - what are you clicking? Human-readable, and used for
diagnostics only

B<Optional:>

C<assert_location> - Argument to pass to C<assert_location>

C<find_link> - what we pass to L<WWW::Mechanize>'s C<find_link> method to
identify the link we want to click.

C<transform_fields> - a code-ref. Will receive $self and the methods arguments,
and expects you to return a hash-ref suitable for passing to L<WWW::Mechanize>'s
C<find_link> method. If you want to search for a link more specifically, and
allow people to pass in, say, a shipment_id, this would be a good way of doing
it.

B<<Exactly one of C<find_link> and C<transform_fields> must be set>>

=cut

sub create_link_method {
    my ( $class, %args ) = @_;

    # This is a good place to check a user is using it correctly...
    $class->_auto_methods_check_params(\%args,
        {
            required => [qw/method_name link_description/],
            optional => [qw/assert_location find_link transform_fields/],
        });

    croak("Either find_link or transform_fields must be set")
        unless ( $args{'find_link'} || $args{'transform_fields'} );

    croak("Only one of find_link or transform_fields may be set")
        if ( $args{'find_link'} && $args{'transform_fields'} );

    $class->meta->add_method(
        $args{'method_name'} => sub {
            my ( $self, @user_options ) = @_;
            $self->show_method_name( $args{'method_name'}, @user_options );
            $self->assert_location( $args{'assert_location'} )
                if defined $args{'assert_location'};

            $self->indent_note("Searching for the $args{'link_description'} link");
            my $link_options = $args{'find_link'} ||
                $args{'transform_fields'}->( $self, @user_options );
            my $link = $self->mech->find_link( %{ $link_options } );

            unless ( $link ) {
                croak "Couldn't find a link matching your description: " .
                    dump( $link_options );
            }
            my $url = $link->url;

            $self->indent_note("Following $args{'link_description'} link: $url");
            $self->mech->get( $url );
            $self->note_status;

            return $self;
        }
    );
}

=head2 create_custom_method

 __PACKAGE__->create_custom_method(
    method_name       => 'delorean__configuration__jingle_the_jangle',
    assert_location   => qr!^/delorean/configurations!,
    handler           => sub {
        my $note_text = $_[1];
        note "\tnote_text: [$note_text]";
        return { note_text => $note_text }
    },
 );

This allows you to do whatever you like! :-) The method name output is shown,
the location assertion is done if you specified one, and then your handler
gets executed with the arguments. After this, C<note_status> is called, and
C<self> returned.

You almost certainly DO NO NEED TO USE THIS. Instead, work out how to use
C<create_form_method> or simplify your method. That said:

Arguments:

B<Required:>

C<method_name> - name of the method to create

C<handler> - sub ref we hand off to

B<Optional:>

C<assert_location> - argument to pass to C<assert_location>

=cut

sub create_custom_method {
    my ( $class, %args ) = @_;

    # This is a good place to check a user is using it correctly...
    $class->_auto_methods_check_params(\%args,
        {
            required => [qw/method_name handler/],
            optional => [qw/assert_location/],
        });

    $class->meta->add_method(
        $args{'method_name'} => sub {
            my ( $self, @args ) = @_;
            $self->show_method_name( $args{'method_name'}, @args );
            $self->assert_location( $args{'assert_location'} )
                if defined $args{'assert_location'};

            $args{'handler'}->( $self, @args );

            $self->note_status;
            return $self;
        }
    );
}

sub _auto_methods_check_params {
    my ( $class, $args, $spec ) = @_;
    for my $key ( @{$spec->{'required'}} ) {
        unless ( defined $args->{$key} ) {
            croak("You must provide a [$key]");
        }
    }
    my %all_keys = map {$_ => 1}
        (@{$spec->{'required'}}, @{$spec->{'optional'}});
    for my $key ( keys %{$args} ) {
        unless ( $all_keys{ $key } ) {
            croak("Unknown option [$key]");
        }
    }
}

=head1 INTERFACE

=head2 show_method_name

Gets called with the string of the method name, and a list of its arguments
at the beginning of created methods. Default implementation spits a dump of this
out to C<indent_note>.

=cut

sub show_method_name {
    my ( $self, $name, @options ) = @_;

    my $output = "->$name(";

    if ( grep { defined $_ } @options ) {
        $output .= ' ' . dump( @options ) . ' ';
    }

    $output .= ')';
    $self->indent_note( $output );
}

=head2 indent_note

This is used for outputting diagnostics. The default implementation is a wrapper
around L<Test::More>'s note functionality, which indents the first string by
the second number + 1.

=cut

sub indent_note {
    my ( $self, $msg, $indent ) = @_;
    require Test::More; # Only load this if this method is called directly

    # Default to 0
    $indent //= 0;

    # This implementation pretty-prints at +1
    $indent++;

    # This is the indent itself...
    my $indent_string = "\t" x $indent;

    # Add the indent
    $msg =~ s/^/$indent_string/mg;

    Test::More::note( $msg );
}

=head2 note_status

Show the status of the HTTP call. This would be an excellent place to look for
messages generated by your web-app, and to fatally die if unexpected errors have
occured. However, this base class knows nothing about that, so we take the easy
option and show the result of Mech's C<success()>.

=cut

sub note_status {
    my ( $self ) = @_;
    my $success = $self->mech->success;

    $self->indent_note("is_success() returned " . (
        $success ? 'true' : 'false'
    ), 1 );
    return $success;
}

=head2 assert_location

=head2 assert_location_failed

Checks we're on the correct page before doing anything. The default
implementation accepts a string or a regular expression, and matches it against
whatever Mechanize thinks is the current unqualified URI. Non-matches call
C<assert_location_failed>.

That would be a good time to check if you have any obvious error statuses on the
page you're on. C<assert_location_failed> accepts the assertion and current URL,
and the default implementation throws a simple fatal error.

=cut

sub assert_location {
    my ( $self, $assertion ) = @_;

    # Sanity-test the obvious stuff
    my $url = $self->mech->uri->path_query;

    croak
        "Can't find a URL, which means your location assertion fails by default"
        unless $url;
    croak "No acceptable location provided" unless $assertion;

    # Perform the match
    if ( ref($assertion) eq 'Regexp' ) {
        do {
            $self->indent_note("URL [$url] matched assertion", 1);
            return 1;
        } if $url =~ $assertion;
    } else {
        do {
            $self->indent_note("URL [$url] matched assertion", 1);
            return 1
        } if $url eq $assertion;
    }

    $self->assert_location_failed( $assertion, $url );
}

sub assert_location_failed {
    my ( $self, $assertion, $url ) = @_;
    croak "Current URL [$url] did not match assertion [$assertion]";
}

=head1 AUTHOR

Peter Sergeant - C<pete@clueball.com>

The original idea for this was conceived during my time working at the most
excellent L<Net-A-Porter|http://www.net-a-porter.com/>, and the work needed to
create this release during one of their regular hack days.

L<Dave Cross|http://metacpan.org/author/DAVECROSS> contributed invaluable ideas
and code.

=cut

1;
