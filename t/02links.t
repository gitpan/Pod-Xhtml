#!/usr/bin/perl -w
#$Id: 02links.t,v 1.5 2005/06/13 14:58:44 simonf Exp $

use strict;
use lib qw(./lib ../lib);
use Test;
use Pod::Xhtml;

if (-d 't') {
	chdir( 't' );
}
require Test_LinkParser;

plan tests => 15;

my $pod_links = new Test_LinkParser();
my $parser = new Pod::Xhtml( LinkParser => $pod_links );

# Links to manpages
ok($parser->seqL('Pod::Xhtml') eq '<cite>Pod::Xhtml</cite>');
ok($parser->seqL('XHTML Podlator|Pod::Xhtml') eq '<b>XHTML Podlator</b> (<cite>Pod::Xhtml</cite>)');
ok($parser->seqL('crontab(5)') eq '<cite>crontab</cite>(5)');

# Links to section in other manpages
ok($parser->seqL('Pod::Xhtml/"SEE ALSO"') eq '<b>SEE ALSO</b> in <cite>Pod::Xhtml</cite>');
ok($parser->seqL('alt text|Pod::Xhtml/"SEE ALSO"') eq '<b>alt text</b> (<b>SEE ALSO</b> in <cite>Pod::Xhtml</cite>)');
ok($parser->seqL('Pod::Xhtml/SYNOPSIS') eq '<b>SYNOPSIS</b> in <cite>Pod::Xhtml</cite>');
ok($parser->seqL('alt text|Pod::Xhtml/SYNOPSIS') eq '<b>alt text</b> (<b>SYNOPSIS</b> in <cite>Pod::Xhtml</cite>)');

# Links to sections in this manpage
# Since 1.41, these are fully resolved at the end of the POD parse
ok($parser->seqL('/"User Guide"') eq '<a href="#<<<User Guide>>>">User Guide</a>');
ok($parser->seqL('alt text|/"User Guide"') eq '<a href="#<<<User Guide>>>">alt text</a>');
ok($parser->seqL('/Notes') eq '<a href="#<<<Notes>>>">Notes</a>');
ok($parser->seqL('alt text|/Notes') eq '<a href="#<<<Notes>>>">alt text</a>');
ok($parser->seqL('"Installation Guide"') eq '<a href="#<<<Installation Guide>>>">Installation Guide</a>');
ok($parser->seqL('alt text|"Installation Guide"') eq '<a href="#<<<Installation Guide>>>">alt text</a>');

# Links to web pages
ok($parser->seqL('http://bbc.co.uk/') eq '<a href="http://bbc.co.uk/">http://bbc.co.uk/</a>');
ok($parser->seqL('http://bbc.co.uk/#top') eq '<a href="http://bbc.co.uk/#top">http://bbc.co.uk/#top</a>');
