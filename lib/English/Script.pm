package English::Script;
# ABSTRACT: Parse English subset and convert to data or code

use 5.014;
use strict;
use warnings;

# use...

# VERSION




1;
__END__

=pod

=begin :badges

=for markdown
[![Build Status](https://travis-ci.org/gryphonshafer/English-Script.svg)](https://travis-ci.org/gryphonshafer/English-Script)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/English-Script/badge.png)](https://coveralls.io/r/gryphonshafer/English-Script)

=end :badges

=head1 SYNOPSIS

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

=head1 DESCRIPTION

The module will parse a limited subset of English (using L<Parse::RecDescent>
grammar) and convert it to either a Perl data structure or YAML. It can then
render this to code. The default renderer is JavaScript.

Why? Well, the goal is to provide a means by which some basic logic can be
written in English and (at least in theory) be read, maintained, and extended
by normal humans (which is to say, non-programmers).

=head1 METHODS

The following are the methods of the module.

=head2 new



=head2 parse



=head2 render



=head2 grammar



=head2 append_grammar



=head2 renderer



=head2 data



=head2 yaml



=head1 SEE ALSO

L<Parse::RecDescent>.

You can also look for additional information at:

=for :list
* L<GitHub|https://github.com/gryphonshafer/English-Script>
* L<MetaCPAN|https://metacpan.org/pod/English::Script>
* L<Travis CI|https://travis-ci.org/gryphonshafer/English-Script>
* L<Coveralls|https://coveralls.io/r/gryphonshafer/English-Script>
* L<CPANTS|http://cpants.cpanauthors.org/dist/English-Script>
* L<CPAN Testers|http://www.cpantesters.org/distro/D/English-Script.html>

=cut
