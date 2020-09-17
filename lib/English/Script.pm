package English::Script {
    # ABSTRACT: Parse English subset and convert to data or code

    use 5.014;
    use strict;
    use warnings;

    use Carp 'croak';
    use Parse::RecDescent;
    use YAML::XS 'Dump';

    # VERSION

    sub new {
        my $self = shift;
        $self = ( ref $self ) ? bless( { %$self, @_ }, ref $self ) : bless( {@_}, $self );

        $self->{grammar} //= q#
            content :
                ( comment | sentence )(s) /^\Z/
                { +{ $item[0] => $item[1] } }
                | <error>

            comment :
                /\([^\(\)]*\)/
                {
                    $item[1] =~ /\(([^\)]+)\)/;
                    +{ $item[0] => ( $1 || '' ) };
                }
                | <error>

            sentence :
                command /[\.;]\s/
                { pop @item; +{@item} }
                | <error>

            command :
                ( say | set | append | add | subtract | multiply | divide | if | otherwise | for )
                { +{@item} }
                | <error>

            say : /\bsay\b/ ( list | expression )
                { +{ $item[0] => $item[2] } }
                | <error>

            set : /\bset\b/ object '=' ( list | expression )
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            append : /\bappend\b/ ( list | expression ) '=' object
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            add : /\badd\b/ expression '=' object
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            subtract : /\bsubtract\b/ expression '`' object
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            multiply : /\bmultiply\b/ object '~' expression
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            divide : /\bdivide\b/ object '~' expression
                { +{ $item[0] => [ $item[2], $item[4] ] } }
                | <error>

            if : /\bif\b/ expression '::' ( block | command )
                { +{ $item[0] => { %{ $item[2] }, %{ $item[4] } } } }
                | <error>

            otherwise : /\botherwise\b,?/ ( block | command )
                { +{ $item[0] => $item[2] } }
                | <error>

            for : /\bfor(?:\s+each)?\b/ object '=^' object block
                {
                    +{
                        $item[0] => {
                            item => $item[2],
                            list => $item[4],
                            %{ $item[5] },
                        }
                    };
                }
                | <error>

            block : '{{{' ( comment | sentence )(s?) '}}}'
                { +{ $item[0] => $item[2] } }
                | <error>

            list :
                object ( list_item_seperator object )(s)
                { +{ shift @item => [ shift @item, @{ $item[0] } ] } }
                | <error>

            list_item_seperator : /,\s*(&&\s+)?/
                | <error>

            expression:
                object sub_expression(s?)
                { +{ $item[0] => [ $item[1], map { @$_ } @{ $item[2] } ] } }
                | <error>

            sub_expression:
                operator object
                { [ $item[1], $item[2] ] }
                | <error>

            operator :
                (
                    '+' | '-' | '/' | '*' |
                    '>=' | '>' | '<=' | '<' | '!@=' | '@=' | '!=' | '==' | '!^=' | '^=' |
                    '&&' | '||'
                )
                {
                    $item[1] =
                        ( $item[1] eq '!@=' ) ? 'not in'     :
                        ( $item[1] eq '@='  ) ? 'in'         :
                        ( $item[1] eq '!^=' ) ? 'not begins' :
                        ( $item[1] eq '^='  ) ? 'begins'     : $item[1];
                    +{@item};
                }
                | <error>

            object : call(s?) ( string | number | word | '=+' | '=-' )(s)
                {
                    pop @{ $item[2] } while (
                        @{ $item[2] } > 1 and
                        $item[2][-1]{word} =~ /^(?:value|string|text|number|list|array)$/
                    );

                    for ( @{ $item[2] } ) {
                        if ( $_ eq '=+' ) {
                           $_ = { boolean => 'true' };
                        }
                        elsif ( $_ eq '=-' ) {
                           $_ = { boolean => 'false' };
                        }
                    }

                    my $data            = {};
                    $data->{calls}      = $item[1] if ( @{$item[1]} );
                    $data->{components} = $item[2] if ( @{$item[2]} );

                    +{ $item[0] => $data };
                }
                | <error>

            call :
                ( '~=' | '$=' | /\[\d+\]/ )
                {
                    $item[1] =
                        ( $item[1] =~ /\[(\d+)\]/ ) ? { 'item' => $1 } :
                        ( $item[1] eq '~='        ) ? 'length'         :
                        ( $item[1] eq '$='        ) ? 'shift'          : $item[1];
                    +{@item};
                }
                | <error>

            string :
                /"[^"]*"/
                {
                    $item[1] =~ /"([^"]*)"/;
                    +{ $item[0] => $1 };
                }
                | <error>

            number :
                /(?:\d+,)*(?:\d+\.)*\d+\b/
                { $item[1] =~ s/[^\d\.]//g; +{@item} }
                | <error>

            word :
                /\w+(?:'s)?\b/
                { +{@item} }
                | <error>
        #;

        $self->renderer( $self->{renderer} // 'JavaScript', $self->{render_args} );

        return $self;
    }

    sub grammar {
        my ( $self, $grammar ) = @_;
        $self->{grammar} = $grammar if ($grammar);
        return $self->{grammar};
    }

    sub append_grammar {
        my ( $self, $grammar ) = @_;
        $self->{grammar} .= $grammar if ($grammar);
        return $self;
    }

    sub _instantiate_renderer {
        my ( $self, $renderer, $render_args ) = @_;

        my $class = __PACKAGE__ . "::$renderer";
        eval "require $class";

        return $class->new( $render_args || {} );
    }

    sub renderer {
        my ( $self, $renderer, $render_args ) = @_;
        $self->{render_args} = $render_args;

        if (
            $renderer and (
                not $self->{renderer_obj} or
                $self->{renderer} and $renderer ne $self->{renderer}
            )
        ) {
            my $class = __PACKAGE__ . "::$renderer";
            eval "require $class";

            $self->{renderer}     = $renderer;
            $self->{renderer_obj} = $self->_instantiate_renderer( $self->{renderer}, $self->{render_args} );
        }

        return $self->{renderer};
    }

    sub prepare_input {
        my ( $self, $input ) = @_;

        my $bits;

        $input =~ s/\(([^\)]+)\)/
            push( @{ $bits->{comments} }, $1 );
            '(' . scalar @{ $bits->{comments} } - 1 . ')';
        /ge;

        $input =~ s/"([^"]+)"/
            push( @{ $bits->{strings} }, $1 );
            '"' . scalar @{ $bits->{strings} } - 1 . '"';
        /ge;

        $input = lc $input;
        $input =~ s/\b(?:a|an|the|value\s+of|list\s+of|there\s+are|there\s+is)\b//g;

        for (
            # call
            [ 'length of'         => '~=' ],
            [ 'removed item from' => '$=' ],

            # operator
            [ 'plus'                        => '+'   ],
            [ 'minus'                       => '-'   ],
            [ 'divided by'                  => '/'   ],
            [ 'times'                       => '*'   ],
            [ 'is greater than or equal to' => '>='  ],
            [ 'is greater than'             => '>'   ],
            [ 'is less than or equal to'    => '<='  ],
            [ 'is less than'                => '<'   ],
            [ 'is not in'                   => '!@=' ],
            [ 'is in'                       => '@='  ],
            [ 'is not'                      => '!='  ],
            [ 'is'                          => '=='  ],
            [ 'does not begin with'         => '!^=' ],
            [ 'begins with'                 => '^='  ],

            # assignment
            [ 'to'   => '=' ],
            [ 'from' => '`' ],
            [ 'by'   => '~' ],

            # logical
            [ 'and' => '&&' ],
            [ 'or'  => '||' ],

            # value
            [ 'true'  => '=+' ],
            [ 'false' => '=-' ],

            # in
            [ 'in' => '=^' ],
        ) {
            $_->[0]  =~ s/\s/\\s+/g;
            $input =~ s/\b($_->[0])\b/$_->[1]/g;
        }

        $input =~ s/(?:,\s*)?\bthen\b/ ::/g;
        $input =~ s/(?:,\s*)?\bapply\b[\w\s]+\bblock\b\s*\./ {{{ /g;
        $input =~ s/[^\.]+\bend[\w\s]+\bblock\b/ }}} /g;

        $input =~ s/\bitem\s*([\d,\.]+)(?:\s*of)?/\[$1\]/g;
        $input =~ s/\((\d+)\)/'(' . $bits->{comments}[$1] . ')'/ge;
        $input =~ s/"(\d+)"/'"' . $bits->{strings}[$1] . '"'/ge;

        return $input . "\n";
    }

    sub parse_prepared_input {
        my ( $self, $prepared_input ) = @_;

        my ( $stderr, $parse_tree );
        {
            local *STDERR;
            open( STDERR, '>', \$stderr );

            local $::RD_ERRORS = 1;
            local $::RD_WARN   = 1;

            $parse_tree = Parse::RecDescent->new( $self->{grammar} )->content($prepared_input);
        }
        if ($stderr) {
            $stderr =~ s/\r?\n[ ]{23}/ /g;
            $stderr =~ s/(?:\r?\n){2,}/\n/g;
            $stderr =~ s/^\s+//mg;

            my @errors = map {
                /^\s*(?<type>\w+)(?:\s+\(line\s+(?<line>\d+)\))?:\s+(?<message>.+)/s;
                my $error = {%+};
                $error->{type} = ucfirst lc $error->{type};
                $error;
            } split( /\n/, $stderr );

            return { errors => \@errors };
        }
        else {
            return $parse_tree;
        }
    }

    sub parse {
        my ( $self, $input ) = @_;
        $self->{data} = $self->parse_prepared_input( $self->prepare_input($input) );
        croak('Failed to parse input') if ( exists $self->{data}{errors} );
        return $self;
    }

    sub data {
        my ($self) = @_;
        return $self->{data};
    }

    sub yaml {
        my ($self) = @_;
        return Dump( $self->{data} );
    }

    sub render {
        my ( $self, $renderer, $render_args ) = @_;

        my $renderer_obj = ( $renderer or $render_args )
            ? $self->_instantiate_renderer(
                $renderer    // $self->{renderer},
                $render_args // $self->{render_args},
            )
            : $self->{renderer_obj};

        return $renderer_obj->render( $self->{data} );
    }
}

package English::Script::JavaScript {
    use 5.014;
    use strict;
    use warnings;

    # VERSION

    sub new {
        my ( $self, $args ) = @_;
        return bless( $args || {}, $self );
    }

    sub render {
        my ( $self, $data ) = @_;
        $self->{objects} = {};
        return $self->content($data);
    }

    sub content {
        my ( $self, $content ) = @_;

        my $text = join( '',
            map {
                ( exists $_->{comment}  ) ? $self->comment( $_->{comment}   ) :
                ( exists $_->{sentence} ) ? $self->sentence( $_->{sentence} ) : ''
            } @{ $content->{content} }
        );

        return join( "\n", (
            map {
                'if ( typeof( ' . $_ . ' ) == "undefined" ) var ' . $_ . ' = {};'
            } sort keys %{ $self->{objects} }
        ), $text );
    }

    sub comment {
        my ( $self, $comment ) = @_;
        ( my $text = $_->{comment} ) =~ s|^|// |mg;
        return $text . "\n";
    }

    sub sentence {
        my ( $self, $sentence ) = @_;
        return $self->command( $sentence->{command} );
    }

    sub command {
        my ( $self, $command ) = @_;

        my ($command_name) = keys %$command;
        my $tree           = $command->{$command_name};
        my $types          = {};

        if ( $command_name eq 'say' ) {
            return join( ' ',
                'console.log(', (
                    ( exists $tree->{list} )       ? $self->list( $tree->{list}             ) :
                    ( exists $tree->{expression} ) ? $self->expression( $tree->{expression} ) : 'undefined'
                ), ')',
            ) . ";\n";
        }
        elsif ( $command_name eq 'set' ) {
            my $object = $self->object( $tree->[0]{object} );
            ( $types->{$object} ) = keys %{ $tree->[1] };

            return join( ' ',
                $object, '=', (
                    ( exists $tree->[1]{expression} )
                        ? $self->expression( $tree->[1]{expression} ) :
                    ( exists $tree->[1]{list} )
                        ? '[ ' . $self->list( $tree->[1]{list} ) . ' ]' : 'undefined'
                )
            ) . ";\n";
        }
        elsif ( $command_name eq 'append' ) {
            my $object        = $self->object( $tree->[1]{object} );
            my ($type)        = keys %{ $tree->[0] };
            my $obj_is_a_list = ( $types->{$object} and $types->{$object} eq 'list' ) ? 1 : 0;

            return join( ' ',
                ( $obj_is_a_list and $type eq 'list' ) ?
                    ( $object . '.push(', $self->list( $tree->[0]{list} ), ')' ) :
                ( not $obj_is_a_list and $type ne 'list' ) ?
                    ( $object, '+=', $self->expression( $tree->[0]{expression} ) ) :
                ( not $obj_is_a_list and $type eq 'list' ) ?
                    ( $object . '= [', $object . ', ', $self->list( $tree->[0]{list} ), ']' ) :
                ( $obj_is_a_list and $type ne 'list' ) ?
                    ( $object . '.push(', $self->expression( $tree->[0]{expression} ), ')' ) : ()
            ) . ";\n";
        }
        elsif ( $command_name eq 'add' ) {
            return join( ' ',
                $self->object( $tree->[1]{object} ), '+=', $self->expression( $tree->[0]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'subtract' ) {
            return join( ' ',
                $self->object( $tree->[1]{object} ), '-=', $self->expression( $tree->[0]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'multiply' ) {
            return join( ' ',
                $self->object( $tree->[0]{object} ), '*=', $self->expression( $tree->[1]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'divide' ) {
            return join( ' ',
                $self->object( $tree->[0]{object} ), '/=', $self->expression( $tree->[1]{expression} ),
            ) . ";\n";
        }
        elsif ( $command_name eq 'if' ) {
            return 'if ( ' . $self->expression( $tree->{expression} ) . " ) {\n" . join( ' ', (
                ( exists $tree->{command} ) ? $self->command( $tree->{command} ) :
                ( exists $tree->{block}   ) ? $self->block( $tree->{block}     ) : ''
            ) ) . "}\n";
        }
        elsif ( $command_name eq 'otherwise' ) {
            return "else {\n" . join( ' ', (
                ( exists $tree->{command} ) ? $self->command( $tree->{command} ) :
                ( exists $tree->{block}   ) ? $self->block( $tree->{block}     ) : ''
            ) ) . "}\n";
        }
        elsif ( $command_name eq 'for' ) {
            my $item = $self->object( $tree->{item}{object} );
            my $list = $self->object( $tree->{list}{object} );

            return 'for ( const ' . $item . ' of ' . $list . " ) {\n" . join( ' ', (
                $self->block( $tree->{block} )
            ) ) . "}\n";
        }

        return '';
    }

    sub block {
        my ( $self, $block ) = @_;
        return join( '',
            map {
                ( exists $_->{comment}  ) ? $self->comment( $_->{comment}   ) :
                ( exists $_->{sentence} ) ? $self->sentence( $_->{sentence} ) : ''
            } @$block
        );
    }

    sub list {
        my ( $self, $list ) = @_;
        return join( ', ', map { $self->object( $_->{object} ) } @$list );
    }

    sub expression {
        my ( $self, $expression ) = @_;

        return map {
            ( exists ( $_->{object} ) ) ? $self->object( $_->{object} ) : $_->{operator}
        } @$expression;
    }

    sub object {
        my ( $self, $object ) = @_;
        my $text = '';

        if ( exists $object->{components} ) {
            unless ( $object->{components}[0]{string} ) {
                $text .= join( '.', map { values %$_ } @{ $object->{components} } );
                $self->{objects}{$text} = 1
                    if ( grep { not exists $_->{number} } @{ $object->{components} } );
            }
            else {
                $text .= '"' . join( '', map { values %$_ } @{ $object->{components} } ) . '"';
            }
        }

        if ( exists $object->{calls} ) {
            for my $call ( reverse map { values %$_ } @{ $object->{calls} } ) {
                if ( $call eq 'length' ) {
                    $text .= '.length';
                }
                elsif ( $call eq 'shift' ) {
                    $text .= '.shift';
                }
                elsif ( ref $call eq 'HASH' and exists $call->{item} ) {
                    $text .= '[' . ( $call->{item} - 1 ) . ']';
                }
            }
        }

        return $text;
    }
}

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

TODO...

=head2 parse

TODO...

=head2 render

TODO...

=head2 grammar

TODO...

=head2 append_grammar

TODO...

=head2 renderer

TODO...

=head2 data

TODO...

=head2 yaml

TODO...

=head2 prepare_input

TODO...

=head2 parse_prepared_input

TODO...

=head1 DEFAULT GRAMMAR

TODO...

=head1 LANGUAGE RENDERER MODULES

TODO...

=head2 JavaScript

TODO... (including settings)

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
