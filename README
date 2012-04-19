NAME
    WWW::Mechanize::Boilerplate - Compose Mechanize macros from
    specifications

DESCRIPTION
    Create WWW::Mechanize `macros` with appropriate boiler plate

BACKGROUND
  The Application
    In the beginning, there was 'the application'. The application had 230
    Apache handlers, each capturing one or more HTTP request. These HTTP
    requests often had subtly different CGI parameters, some only made sense
    when you were already on certain pages, and all of them, eventually,
    needed accessing from automated functional tests.

    The tests didn't want to care about the underlying HTTP mechanism, or
    even the underlying HTML. The test just wanted to be able to say:

     $mech->flux_capacitor__submit_recallibration({
        jigawatts => 10_000
     });

    So why not just use WWW::Mechanize? That's what it's for, right? You can
    simply say:

     $mech->submit_form( with_fields => {
        value => 10_000,
        units => 'jigawatts',
        understand_risks => 'confirmed'
     });

    And this works just fine for a single test on the Flux Capacitor page.

  It's a Trap!
    But clearly this is a trap. Because as we're all adults, actually, we
    want to check we're on the right page first, because it'll be super
    confusing otherwise if the former method left us on the wrong page, and
    we're trying to work out why we're not writing to the database.

    And we also want to add a whole bunch of optional diagnostic output to
    help the poor developer trying to read the output on Jenkins from where
    everything stopped working.

    And actually, the form has two buttons *for historical reasons*, one of
    which should be used for over 1,000 *jigawtts*, and one for under. So
    you need to add the form selection code in too.

    Did I mention 14 different test scripts use this page and need to submit
    the jigawatt form, and the team that sits across the office for you are
    making noises about changing the form structure in the next iteration?

  Abstraction
    All of this is pretty easily solved. You write a nice method against
    your WWW::Mechanize subclass called 'submit_the_flux_capacitor_form',
    and the problem is solved.

    For that form, anyway. On that handler.

    Now you just need to code up the next 400 possible HTTP actions your
    test might want to take, and you're home clear...

    And that's the problem this module solves, for us. It allows you to very
    easily create methods that generate HTTP requests, with useful boiler
    plate, and most importantly, in data.

    Here a simple example for creating a method for getting to the jigawat
    form:

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

     $mech->delorean__configuration
          ->delorean__configuration__flux_capacitor( jigawatts => 10_000 );

    Optionally seeing the following output, via Test::More's "note()".

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

ARCHITECTUAL OVERVIEW
    When you instantiate a new object of this class, it needs a
    WWW::Mechanize delegate to perform its actual actions.

    It also provides a rich interface for you to poke around in the methods
    created.

    We document the method-creation methods in "METHOD CREATION METHODS"
    below, and we document the interface in INTERFACE.

METHOD CREATION METHODS
  create_fetch_method
     ->create_fetch_method(
        method_name      => 'delorean__configuration',
        page_description => 'configuration page for the Delorean',
        page_url         => '/delorean/configuration?car_id=',
        required_param   => 'Car ID'
     );

    Creates a method that retrieves a URL. Arguments:

    Required:

    "method_name" - name of the method to create

    "page_description" - what's the page called? Used for diagnostics

    "page_url" - the page to fetch

    Optional:

    "assert_location" - Argument to pass to "assert_location()"

    "required_param" - If your URL needs a trailing atom to complete it, set
    this to a true value. The user of the method will be required to provide
    an argument, and it'll be named (in diagnostic output) to the value you
    assigned it.

    That means, in the value above, when you call the method, you also must
    provide an argument:

     $framework->delorean__configuration( 1234 );

    There will be a diagnostic method printed:

     # Car ID is [1234]

    And the following URL will be retrieved:

     C</delorean/configuration?car_id=1234>

  create_form_method
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

    Required:

    "method_name" - name of the method to create

    "form_name" - the name attribute of the target form. Passed to
    WWW::Mechanize's "form_name()" method. You can pass in a coderef here,
    which will get called just like "transform_fields" and should return a
    string.

    "form_description" - the human-readable description of the form you're
    submitting. You don't need to append the word 'form' to this.

    "assert_location" - Argument to pass to "assert_location()"

    Optional:

    "transform_fields" - a code-ref. Will receive $self and the methods
    arguments, and expects you to return a hash-ref suitable for passing to
    WWW::Mechanize's "set_fields" method. This is a great place to put in
    default arguments, and also a great place to use "note()" to tell the
    test output reader what's going on.

    "form_button" - argument to pass to WWW::Mechanize's "submit_form" value
    as "button". Used for specifying which button to use to submit a form.
    This is a string of the button name. You can pass in a coderef here,
    which will get called just like "transform_fields" and should return a
    string.

  delorean__configuration__flux_capacitor
     ->create_link_method(
        method_name      => 'delorean__configuration__current_stats',
        link_description => 'Current Stats',
        find_link        => { text => 'View Current Stats' },
        assert_location  => '/delorean/configurations'
     );

    Creates a method that finds a link on the current page and clicks it.

    Arguments:

    Required:

    "method_name" - name of the method to create

    "link_description" - what are you clicking? Human-readable, and used for
    diagnostics only

    Optional:

    "assert_location" - Argument to pass to "assert_location"

    "find_link" - what we pass to WWW::Mechanize's "find_link" method to
    identify the link we want to click.

    "transform_fields" - a code-ref. Will receive $self and the methods
    arguments, and expects you to return a hash-ref suitable for passing to
    WWW::Mechanize's "find_link" method. If you want to search for a link
    more specifically, and allow people to pass in, say, a shipment_id, this
    would be a good way of doing it.

    <Exactly one of "find_link" and "transform_fields" must be set>

  create_custom_method
     __PACKAGE__->create_custom_method(
        method_name       => 'delorean__configuration__jingle_the_jangle',
        assert_location   => qr!^/delorean/configurations!,
        handler           => sub {
            my $note_text = $_[1];
            note "\tnote_text: [$note_text]";
            return { note_text => $note_text }
        },
     );

    This allows you to do whatever you like! :-) The method name output is
    shown, the location assertion is done if you specified one, and then
    your handler gets executed with the arguments. After this, "note_status"
    is called, and "self" returned.

    You almost certainly DO NO NEED TO USE THIS. Instead, work out how to
    use "create_form_method" or simplify your method. That said:

    Arguments:

    Required:

    "method_name" - name of the method to create

    "handler" - sub ref we hand off to

    Optional:

    "assert_location" - argument to pass to Test::XT::Flow's
    "assert_location"

INTERFACE
  show_method_name
    Gets called with the string of the method name, and a list of its
    arguments at the beginning of created methods. Default implementation
    spits a dump of this out to "indent_note".

  indent_note
    This is used for outputting diagnostics. The default implementation is a
    wrapper around Test::More's note functionality, which indents the first
    string by the second number + 1.

  note_status
    Show the status of the HTTP call. This would be an excellent place to
    look for messages generated by your web-app, and to fatally die if
    unexpected errors have occured. However, this base class knows nothing
    about that, so we take the easy option and show the result of Mech's
    "success()".

  assert_location
  assert_location_failed
    Checks we're on the correct page before doing anything. The default
    implementation accepts a string or a regular expression, and matches it
    against whatever Mechanize thinks is the current unqualified URI.
    Non-matches call "assert_location_failed".

    That would be a good time to check if you have any obvious error
    statuses on the page you're on. "assert_location_failed" accepts the
    assertion and current URL, and the default implementation throws a
    simple fatal error.

