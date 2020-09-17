# NAME

English::Script - Parse English subset and convert to data or code

# VERSION

version 0.001

[![Build Status](https://travis-ci.org/gryphonshafer/English-Script.svg)](https://travis-ci.org/gryphonshafer/English-Script)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/English-Script/badge.png)](https://coveralls.io/r/gryphonshafer/English-Script)

# SYNOPSIS

    use English::Script;

    my $js = English::Script->new->parse('Set the answer to 42.')->render;

    $es = English::Script->new(
        grammar  => '# grammar',
        renderer => 'JavaScript',
    );

    my $grammar  = $es->grammar('# set grammar');
    $es          = $es->append_grammar('# append grammar');
    my $renderer = $es->renderer('JavaScript');

    $es = $es->parse('Set the answer to 42.');

    my $data = $es->data;
    my $yaml = $es->yaml;

    my $js = $es->render;
    $js    = $es->render('JavaScript');
    $js    = $es->render( 'JavaScript', {} );

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

## parse

## render

## grammar

## append\_grammar

## renderer

## data

## yaml

# SEE ALSO

[Parse::RecDescent](https://metacpan.org/pod/Parse%3A%3ARecDescent).

You can also look for additional information at:

- [GitHub](https://github.com/gryphonshafer/English-Script)
- [MetaCPAN](https://metacpan.org/pod/English::Script)
- [Travis CI](https://travis-ci.org/gryphonshafer/English-Script)
- [Coveralls](https://coveralls.io/r/gryphonshafer/English-Script)
- [CPANTS](http://cpants.cpanauthors.org/dist/English-Script)
- [CPAN Testers](http://www.cpantesters.org/distro/D/English-Script.html)

# AUTHOR

Gryphon Shafer <gryphon@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
