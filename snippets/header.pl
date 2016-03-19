# https://github.com/hatena/Hatena-Textbook/blob/master/foundation-of-programming-perl.md
use strict;
use warnings;

use utf8;
use Encode;

print length "ほげ";

# print "ほげ\n";
print encode_utf8 "ほげ\n";
