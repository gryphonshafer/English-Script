# NAME

English::Script - Parse English subset and convert to data or code

# VERSION

version 1.06

[![test](https://github.com/gryphonshafer/English-Script/workflows/test/badge.svg)](https://github.com/gryphonshafer/English-Script/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/English-Script/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/English-Script)

# SYNOPSIS

    use English::Script;

    my $js = English::Script->new->parse('Set the answer to 42.')->render;

    my $es = English::Script->new(
        grammar     => '# grammar',
        renderer    => 'JavaScript',
        render_args => {},
    );

    my $grammar  = $es->grammar('# set grammar');
    $es          = $es->append_grammar('# append grammar');
    my $renderer = $es->renderer('JavaScript');
    $renderer    = $es->renderer( 'JavaScript', {} );

    $es = $es->parse('Set the answer to 42.');

    my $data = $es->data;
    my $yaml = $es->yaml;

    $js = $es->render;
    $js = $es->render('JavaScript');
    $js = $es->render( 'JavaScript', {} );

# DESCRIPTION

The module will parse a limited subset of English (using [Parse::RecDescent](https://metacpan.org/pod/Parse%3A%3ARecDescent)
grammar) and convert it to either a Perl data structure or YAML. It can then
render this to code. The default renderer is JavaScript.

Why? Well, the goal is to provide a means by which some basic logic can be
written in English and (at least in theory) be read, maintained, and extended
by normal humans (which is to say, non-programmers).

# METHODS

The following are the methods of the module.

## new

Returns an instantiated object of the class.

    my $js = English::Script->new;

Optionally, you can provide certain settings.

    $es = English::Script->new(
        grammar     => '# grammar',   # replaces default grammer
        renderer    => 'JavaScript',  # set the renderer; default: JavaScript
        render_args => {},            # arguments for the renderer
    );

Renderers are subclasses of English::Script. The default is
English::Script::JavaScript, which ships with English::Script. The name provided
via the `renderer` property is appended to "English::Script::" to locate the
renderer class.

## parse

Parse a string input based on the grammar.

    $es = $es->parse('Set the answer to 42.');

This method will return the object. If parsing fails, an error will be thrown.
You can catch this error and then inspect `data` to get a list of all errors.

    use exact;
    use DDP;

    try {
        $es->parse('Set the answer to 42.');
    }
    catch {
        p $es->data->{errors};
    };

## render

If no arguments are provided, this method will call whatever renderer is set
via the `renderer` attribute to render code from the data parsed.

    $js = $es->render;

You can optionally explicitly set a renderer or a renderer and arguments for
the renderer.

    $js = $es->render('JavaScript');
    $js = $es->render( 'JavaScript', {} );

The method will return the rendered code as a scalar string.

## grammar

This is a getter/setter for the grammar, which is a string suitable for
[Parse::RecDescent](https://metacpan.org/pod/Parse%3A%3ARecDescent).

    my $grammar = $es->grammar('# set grammar');

## append\_grammar

Append a string to whatever's currently set in the `grammar` attribute.

    $es = $es->append_grammar('# append grammar');

This method will return the object.

## renderer

This is a getter/setter for the renderer. You can provide either the name of a
renderer (which should be the suffix added to "English::Script::" to locate the
renderer class) or the name of the renderer and a hashref of arguments for that
renderer.

    my $renderer = $es->renderer('JavaScript');
    $renderer    = $es->renderer( 'JavaScript', {} );

## data

Returns the Perl data structure of whatever was succesfully `parse`d.

    my $data = $es->data;

## yaml

Returns YAML of whatever was succesfully `parse`d.

    my $yaml = $es->yaml;

# DEFAULT GRAMMAR

The default grammar is a limited and simple set of basic English phrases. The
intent of this "language" is not to be particularly expressive, but provide
just enough to be useful in basic situations.

Parsable input needs to be composed of sentences. Line breaks and other spacing
is ignored, but purely for the sake easy reading, the examples below generally
follow a sentence being all on one line. This is not required.

## Say

To "say" something means to output it in some way. For the JavaScript renderer,
this means a call to `console.log`. Say commands require an expression.
Expressions contain at least one object and possibly some operations. An object
is a string, number, word, or call.

Here are some simple examples:

    Say 42.
    Say "Hello World".
    Say 42 plus 1138 times 13 divided by 12.

## Set

The "set" command assigns a value derived from an expression to an object.

    Set prime to 3.
    Set the special prime value to 3.
    Set the answer to 123,456.78.

Numbers can be floating point and contain commas, which will be ignored. For
example, "123,456.78" becomes `123456.78`.

In the case of multiple words (or words and numbers) provided as an object, the
assumption will be that these are sequences of objects in a tree. For example:

    Set the special prime value to 3.

The special prime" becomes `special.prime` in JavaScript.

Certain words are ignored completely, like "the" and "a" and all other articles.
Also phrases like "value of" or "list of" or "there are" and "there is" are
ignored. For objects, words like "list" or "value" or "text" or "number" are
ignored. For example:

    Set the special prime list value string text number list array to 3.

The object above becomes `special.prime` in JavaScript (and is assigned the
integer 3).

Words and numbers can form an object. For example:

    Set the sum of 27 to the value of 3 plus 5 times 10 divided by 2 minus 1.

The object above is `sum.of.27`.

In all cases, everything outside of strings, denoted by double-quotes, will be
considered case-insensitive.

## Comments

Comments are any text between parentheses. The text can contain line-breaks or
any other spacing. However, comments must not be embedded inside sentences. They
can be inside blocks, like in "if" or "for" blocks, but in parallel to
sentences.

    (This is a single-line comment.)

    (This is a
    multi-line comment.)

    If prime is 3, then apply the following block.
        Set the answer to 42.
        (This is a comment.)
    This ends the block.

Note that the spacing and line breaks in the examples above is purely for easier
reading. It's not required.

## Lists

To create an array, assign a list to an object.

    Set the primes to 5, 6, and 7.

The "and" isn't necessarily required; however, the spaces and commas are
required.

You can reference a specific item in a list by number (starting at 1):

    Set the favorite number to item 1 of favorite numbers.

Given a list stored in `answer`, you can then `shift` off a value:

    Set the prime value to a removed item from the primes list.

## Length

You can get the length of a list (the number of items it contains) or the length
of a string by seeking it's "length":

    Set string size to the length of strings example.
    Set primes size to the length of the primes list.

You can also find the length of a specific item of a list:

    Set the special size to the length of item 1 of favorite numbers.

## Append

You can append to a string or to a list.

    Append "+" to the answer text.
    Append 9 to the primes list.

## Math

Basic math functions are supported:

    Add 42 to the favorite number.
    Subtract 42 from the favorite number.
    Multiply the favorite number by 42.
    Divide the favorite number by 42.

## If

Basic conditionals are supported.

    If prime is 3, then set add 3 to the sum of primes.

You can also setup blocks. Note that in the following example, the spacing and
line breaks exist purely to aid in reading. They're not required.

    If prime is 3, then apply the following block.
        Set the answer to 42.
        Set THX to 1138.
    This ends the block.

You can name the blocks as well, if you want. So you could write "then apply
the following set up some things block."

The booleans of "true" and "false" are supported.

    Set something to true.
    If something is true, then say "It's true!".

## Otherwise

The "otherwise" command works as an `else`, but it must be in an immediately
following sentence from an "if" sentence.

    If the prime is 3, then set result to true. Otherwise, set result to false.

You can create the equivalent of an `else if` via:

    If the prime is 3, then set result to true.
    Otherwise, if the answer is not 42, then set result to false.

## Conditionals

A few basic conditionals are supported.

- is
- is not
- is less than
- is greater than
- is less than or equal to
- is greater than or equal to

You can check if a string is in a larger string, if an item is in a list, or
if a string begins with another string or not using:

- is in
- is not in
- begins with
- does not begin with

Basic logical combinations of conditionals are possible with:

- and
- or

## For

For loops that iterate through items in a list are supported.

    Set primes to 3, 5, and 7. For each prime in primes, apply the following
    block. Add prime to sum. This ends the block.

## Variable Scope

All variables are scoped globally. Everywhere. Always. If you setup a for loop
and name the iterator something, that something will available everywhere.

# LANGUAGE RENDERER MODULES

Language renderer modules must support a `new()` method and a `render()`
method. Beyond that, you can do just about whatever you want to make rendering
work.

## JavaScript

The default renderer "JavaScript" will render... wait for it... JavaScript.

    English::Script->new(
        renderer    => 'JavaScript',
        render_args => { compress => 'clean' },
    )->parse('Set answer to 42.')->render;

The optional `render_args` value if provided should be a hashref of settings
that are passed directly to [JavaScript::Packer](https://metacpan.org/pod/JavaScript%3A%3APacker) as options.

# SEE ALSO

[Parse::RecDescent](https://metacpan.org/pod/Parse%3A%3ARecDescent), [JavaScript::Packer](https://metacpan.org/pod/JavaScript%3A%3APacker).

You can also look for additional information at:

- [GitHub](https://github.com/gryphonshafer/English-Script)
- [MetaCPAN](https://metacpan.org/pod/English::Script)
- [GitHub Actions](https://github.com/gryphonshafer/English-Script/actions)
- [Codecov](https://codecov.io/gh/gryphonshafer/English-Script)
- [CPANTS](http://cpants.cpanauthors.org/dist/English-Script)
- [CPAN Testers](http://www.cpantesters.org/distro/D/English-Script.html)

# AUTHOR

Gryphon Shafer <gryphon@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2050 by Gryphon Shafer.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
