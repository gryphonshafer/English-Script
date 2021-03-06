use Test2::V0;
use English::Script;

my $es;
ok( lives { $es = English::Script->new }, 'new' ) or note $@;

is(
    $es->parse(
        ( ref $_->[1] ) ? join( "\n", @{ $_->[1] } ) : $_->[1]
    )->render,
    ( ( ref $_->[2] ) ? join( "\n", @{ $_->[2] } ) : $_->[2] ) . "\n",
    $_->[0],
) for (
    [
        'add number to object',
        'Add 42 to favorite number.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = "";',
            'favorite += 42;',
        ],
    ],
    [
        'subtract number from object',
        'Subtract 42 from favorite number.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = "";',
            'favorite -= 42;',
        ],
    ],
    [
        'multiply object by number',
        'Multiply favorite number by 42.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = "";',
            'favorite *= 42;',
        ],
    ],
    [
        'divide object by number',
        'Divide favorite number by 42.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = "";',
            'favorite /= 42;',
        ],
    ],
);

done_testing;
