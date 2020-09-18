use strict;
use warnings;
use Test::Most;

use_ok('English::Script');

my $es;
lives_ok( sub { $es = English::Script->new }, 'new' );

is(
    $es->parse(
        ( ref $_->[1] ) ? join( "\n", @{ $_->[1] } ) : $_->[1]
    )->render,
    ( ( ref $_->[2] ) ? join( "\n", @{ $_->[2] } ) : $_->[2] ) . "\n",
    $_->[0],
) for (
    [
        'single-line comment',
        '(This is a single-line comment.)',
        "// This is a single-line comment.",
    ],
    [
        'multi-line comment',
        [
            '(This is a',
            'multi-line comment.)',
        ],
        [
            '// This is a',
            '// multi-line comment.',
        ],
    ],
    [
        'say a number',
        'Say 42.',
        'console.log( 42 );',
    ],
    [
        'say a string',
        'Say "Hello World".',
        'console.log( "Hello World" );',
    ],
    [
        'say an expression',
        'Say 42 plus 1138 times 13 divided by 12.',
        'console.log( 42 + 1138 * 13 / 12 );',
    ],
    [
        'set simple object',
        'Set prime to 3.',
        [
            'if ( typeof( prime ) == "undefined" ) var prime;',
            'prime = 3;'
        ],
    ],
    [
        'set complex object',
        'Set special prime to 3.',
        [
            'if ( typeof( special ) == "undefined" ) var special = {};',
            'if ( typeof( special.prime ) == "undefined" ) var special.prime;',
            'special.prime = 3;'
        ],
    ],
    [
        'set complex object that starts with number',
        'Set 42 special prime to 3.',
        [
            'if ( typeof( _42 ) == "undefined" ) var _42 = {};',
            'if ( typeof( _42.special ) == "undefined" ) var _42.special = {};',
            'if ( typeof( _42.special.prime ) == "undefined" ) var _42.special.prime;',
            '_42.special.prime = 3;'
        ],
    ],
    [
        'ignore superfluous words',
        'Set the special prime list value string text number list array to 3.',
        [
            'if ( typeof( special ) == "undefined" ) var special = {};',
            'if ( typeof( special.prime ) == "undefined" ) var special.prime;',
            'special.prime = 3;'
        ],
    ],
    [
        'complex object and complex expression',
        'Set the sum of 27 to the value of 3 plus 5 times 10 divided by 2 minus 1.',
        [
            'if ( typeof( sum ) == "undefined" ) var sum = {};',
            'if ( typeof( sum.of ) == "undefined" ) var sum.of = {};',
            'if ( typeof( sum.of.27 ) == "undefined" ) var sum.of.27;',
            'sum.of.27 = 3 + 5 * 10 / 2 - 1;'
        ],
    ],
    [
        'set a floating point number with commas',
        'Set the answer to 123,456.78.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer;',
            'answer = 123456.78;'
        ],
    ],
    [
        'set a list',
        'Set the answer to 5, 6, 7.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer = [];',
            'answer = [ 5, 6, 7 ];',
        ],
    ],
    [
        'set a list (wrongly) without spaces',
        'Set the answer to 5,6,7.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer;',
            'answer = 567;',
        ],
    ],
    [
        'set a list with an and',
        'Set the answer to 5, 6, and 7.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer = [];',
            'answer = [ 5, 6, 7 ];',
        ],
    ],
    [
        'length',
        'Set string size to the length of strings example.',
        [
            'if ( typeof( string ) == "undefined" ) var string = {};',
            'if ( typeof( string.size ) == "undefined" ) var string.size;',
            'if ( typeof( strings ) == "undefined" ) var strings = {};',
            'if ( typeof( strings.example ) == "undefined" ) var strings.example;',
            'string.size = strings.example.length;',
        ],
    ],
    [
        'shift',
        'Set number to a removed item from favorite numbers.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = {};',
            'if ( typeof( favorite.numbers ) == "undefined" ) var favorite.numbers = [];',
            'if ( typeof( number ) == "undefined" ) var number;',
            'number = favorite.numbers.shift;',
        ],
    ],
    [
        'append "+" to a variable',
        'Append "+" to the answer text.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer;',
            'answer += "+";',
        ],
    ],
    [
        'append an integer to a list',
        [
            'Set the primes list to 3, 5, and 7.',
            'Append 9 to the primes list.',
        ],
        [
            'if ( typeof( primes ) == "undefined" ) var primes = [];',
            'primes = [ 3, 5, 7 ];',
            'primes.push( 9 );',
        ],
    ],
    [
        'add number to object',
        'Add 42 to favorite number.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite;',
            'favorite += 42;',
        ],
    ],
    [
        'subtract number from object',
        'Subtract 42 from favorite number.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite;',
            'favorite -= 42;',
        ],
    ],
    [
        'multiply object by number',
        'Multiply favorite number by 42.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite;',
            'favorite *= 42;',
        ],
    ],
    [
        'divide object by number',
        'Divide favorite number by 42.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite;',
            'favorite /= 42;',
        ],
    ],
    [
        'set variable to item in array',
        'Set number to item 1 of favorite numbers.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = {};',
            'if ( typeof( favorite.numbers ) == "undefined" ) var favorite.numbers;',
            'if ( typeof( number ) == "undefined" ) var number;',
            'number = favorite.numbers[0];',
        ],
    ],
    [
        'set variable to function of item in array',
        'Set number to the length of item 1 of favorite numbers.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = {};',
            'if ( typeof( favorite.numbers ) == "undefined" ) var favorite.numbers;',
            'if ( typeof( number ) == "undefined" ) var number;',
            'number = favorite.numbers[0].length;',
        ],
    ],
    [
        'if conditional and boolean',
        'If prime is 3, then set result to true.',
        [
            'if ( typeof( prime ) == "undefined" ) var prime;',
            'if ( typeof( result ) == "undefined" ) var result;',
            'if ( prime == 3 ) {',
            'result = true;',
            '}',
        ],
    ],
    [
        'if boolean then say string',
        'If something is true, then say "It\'s true!".',
        [
            'if ( typeof( something ) == "undefined" ) var something;',
            'if ( something == true ) {',
            'console.log( "It\'s true!" );',
            '}',
        ],
    ],
    [
        'complex conditional with contains',
        [
            'Set prime to 3.',
            'Set primes to 3, 5, and 7.',
            'If prime is 3 and 7 is in primes and something is true, then set answer to 42.',
        ],
        [
            'if ( typeof( answer ) == "undefined" ) var answer;',
            'if ( typeof( prime ) == "undefined" ) var prime;',
            'if ( typeof( primes ) == "undefined" ) var primes = [];',
            'if ( typeof( something ) == "undefined" ) var something;',
            'prime = 3;',
            'primes = [ 3, 5, 7 ];',
            'if ( prime == 3 && primes.indexOf( 7 ) > -1 && something == true ) {',
            'answer = 42;',
            '}',
        ],
    ],
    # [
    #     'conditional with block containing 2 statements',
    #     [
    #         'If prime is 3, then apply the following block.',
    #         'Set answer to 42.',
    #         '(This is a comment.)',
    #         'This ends the block.',
    #     ],
    #     [
    #         'if ( typeof( answer ) == "undefined" ) var answer;',
    #         'if ( typeof( prime ) == "undefined" ) var prime;',
    #         'if ( prime == 3 ) {',
    #         'answer = 42;',
    #         '// This is a comment.',
    #         '}',
    #     ],
    # ],
    # [
    #     'if conditional statement otherwise statement',
    #     'If prime is 3, then set result to true. Otherwise, set result to false.',
    #     [
    #         'if ( typeof( false ) == "undefined" ) var false = {};',
    #         'if ( typeof( prime ) == "undefined" ) var prime = {};',
    #         'if ( typeof( result ) == "undefined" ) var result = {};',
    #         'if ( typeof( true ) == "undefined" ) var true = {};',
    #         'if ( 3 ) {',
    #         'result = true;',
    #         '}',
    #         'else {',
    #         'result = false;',
    #         '}',
    #     ],
    # ],
    # [
    #     'if conditional then statement otherwise if conditional then statement',
    #     'If prime is 3, then set result to true. Otherwise, if prime is not 42, then set result to true.',
    #     [
    #         'if ( typeof( prime ) == "undefined" ) var prime = {};',
    #         'if ( typeof( result ) == "undefined" ) var result = {};',
    #         'if ( typeof( true ) == "undefined" ) var true = {};',
    #         'if ( 3 ) {',
    #         'result = true;',
    #         '}',
    #         'else {',
    #         'if ( 3 ) {',
    #         'result = true;',
    #         '}',
    #         '}',
    #     ],
    # ],
    # [
    #     'greather than and length of',
    #     'If the object is greater than the length of the other object, then say 42.',
    #     [
    #         'if ( typeof( object ) == "undefined" ) var object = {};',
    #         'if ( typeof( other.object ) == "undefined" ) var other.object = {};',
    #         'if ( 3 ) {',
    #         'console.log( 42 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'greater than or equal to',
    #     'If the thing value is greater than or equal to the stuff value plus 17, then say 43.',
    #     [
    #         'if ( typeof( stuff ) == "undefined" ) var stuff = {};',
    #         'if ( typeof( thing ) == "undefined" ) var thing = {};',
    #         'if ( 5 ) {',
    #         'console.log( 43 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'greater than',
    #     'If the thing value is greater than the stuff value, then say 43.',
    #     [
    #         'if ( typeof( stuff ) == "undefined" ) var stuff = {};',
    #         'if ( typeof( thing ) == "undefined" ) var thing = {};',
    #         'if ( 3 ) {',
    #         'console.log( 43 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'less than or equal to',
    #     'If the thing value is less than or equal to 42, then say 42.',
    #     [
    #         'if ( typeof( thing ) == "undefined" ) var thing = {};',
    #         'if ( 3 ) {',
    #         'console.log( 42 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'less than',
    #     'If the thing value is less than 42, then say 42.',
    #     [
    #         'if ( typeof( thing ) == "undefined" ) var thing = {};',
    #         'if ( 3 ) {',
    #         'console.log( 42 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'is not',
    #     'If the thing value is not in 42, then say 42.',
    #     [
    #         'if ( typeof( thing ) == "undefined" ) var thing = {};',
    #         'if ( 3 ) {',
    #         'console.log( 42 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'is in',
    #     'If the thing value is in 42, then say 42.',
    #     [
    #         'if ( typeof( thing ) == "undefined" ) var thing = {};',
    #         'if ( 3 ) {',
    #         'console.log( 42 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'is not',
    #     'If the thing value is not 42, then say 42.',
    #     [
    #         'if ( typeof( thing ) == "undefined" ) var thing = {};',
    #         'if ( 3 ) {',
    #         'console.log( 42 );',
    #         '}',
    #     ],
    # ],
    # [
    #     'for each item in items block',
    #     'For each prime in primes, apply the following block. Add prime to sum. This ends the block.',
    #     [
    #         'if ( typeof( prime ) == "undefined" ) var prime = {};',
    #         'if ( typeof( primes ) == "undefined" ) var primes = {};',
    #         'if ( typeof( sum ) == "undefined" ) var sum = {};',
    #         'for ( const prime of primes ) {',
    #         'sum += prime;',
    #         '}',
    #     ],
    # ],
);

done_testing;
