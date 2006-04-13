#!/usr/bin/perl -w
#$Id: 01defaults.t,v 1.19 2006/04/07 14:14:39 mattheww Exp $

use strict;
use lib qw(./lib ../lib);
use Test;
use Pod::Xhtml;
use Getopt::Std;

getopts('tTs', \my %opt);
if ($opt{t} || $opt{T}) {
	require Log::Trace;
	import Log::Trace print => {Deep => $opt{T}};
}

if (-d 't') {
	chdir( 't' );
}
require Test_LinkParser;

my $filecont;
my $podia = 'a.pod';
my $podoa = 'a.xhtml';

unlink $podoa if -e $podoa;

plan tests => 13;

ok( $Pod::Xhtml::VERSION );

my $pod_links = Test_LinkParser->new();
my $parser = Pod::Xhtml->new(LinkParser => $pod_links);

#### try parsing from file
ok( ! -f $podoa );
$parser->parse_from_file( $podia, $podoa );
ok( -f $podoa );

$filecont = readfile( $podoa );
ok( $filecont );
ok( index( $filecont, cont_a() ) > -1 );
undef $filecont;
unlink $podoa;

#### parsing from filehandles
ok( ! -f $podoa );
open(OUT, '>'.$podoa) or die("Can't open out $podoa: $!");
$parser->parse_from_filehandle( \*DATA, \*OUT );
close OUT;
ok( -f $podoa );

$filecont = readfile( $podoa );
ok( $filecont );
ok( index( $filecont, cont_a() ) > -1 );
undef $filecont;
unlink $podoa unless $opt{'s'};

my $podib = 'b.pod';
my $podob = 'b.xhtml';

ok ( !-f $podob );
$parser->parse_from_file( $podib, $podob );
ok ( -f $podob );

$filecont = readfile( $podob );
ok( $filecont );
ok( index( $filecont, cont_b() ) > -1 );
undef $filecont;
unlink $podob unless $opt{'s'};

sub cont_a {
return q(
<body>
<div class="pod">
<!-- INDEX START -->
<h3 id="TOP">Index</h3>
<ul>
	<li><a href="#NAME">NAME</a></li>
	<li><a href="#SYNOPSIS">SYNOPSIS</a></li>
	<li><a href="#DESCRIPTION">DESCRIPTION</a></li>
	<li><a href="#Sed_diam_nomumny">Sed diam nomumny</a></li>
	<li><a href="#METHODS">METHODS</a></li>
	<li><a href="#ATTRIBUTES">ATTRIBUTES</a></li>
	<li><a href="#ISSUES">ISSUES</a><br />
<ul>
	<li><a href="#KNOWN_ISSUES">KNOWN ISSUES</a></li>
	<li><a href="#UNKNOWN_ISSUES">UNKNOWN ISSUES</a></li>
</ul>
</li>
</ul>
<hr />
<!-- INDEX END -->

<h1 id="NAME">NAME</h1><p><a href="#TOP" class="toplink">Top</a></p>

<p>A - Some demo POD</p>
<h1 id="SYNOPSIS">SYNOPSIS</h1><p><a href="#TOP" class="toplink">Top</a></p>

<pre>	use Pod::Xhtml;
	my $px = new Pod::Xhtml;

</pre>
<h1 id="DESCRIPTION">DESCRIPTION</h1><p><a href="#TOP" class="toplink">Top</a></p>

<p>This is a module to translate POD to Xhtml. Lorem ipsum <b>Dolor</b> in <cite>Dolor</cite> sit amet consectueur adipscing elit. Sed diam nomumny.
This is a module to translate POD to Xhtml. <a href="#Lorem">The Lorem entry</a> ipsum dolor sit amet
consectueur adipscing elit. Sed diam nomumny.
This is a module to translate <cite>POD</cite> to Xhtml. <strong>Lorem</strong> ipsum <i>dolor</i> sit amet
<code>consectueur adipscing</code> elit. <span id="Sed_diam_nomumny">Sed diam nomumny</span>.
This is a module to translate POD to Xhtml. See <a href="#Lorem">Lorem</a> ipsum dolor sit amet
consectueur adipscing elit. Sed diam <cite>nomumny</cite>. <a href="http://foo.bar/baz/">http://foo.bar/baz/</a></p>
<h1 id="METHODS">METHODS</h1><p><a href="#TOP" class="toplink">Top</a></p>

<dl>
	<dt>Nested blocks</dt>
	<dd>
		<p>Pod::Xhtml now supports nested over/item/back blocks:</p>
		<p>
			<ul>
					<li>Point 1				</li>
					<li>Point Number 2				</li>
					<li>Item three				</li>
					<li>Point four
<br /><br />Still point four
<br /><br /><pre>  This is verbatim text in a bulleted list

</pre></li>
</ul>

		</p>
<pre>  This is verbatim test in a regular list

</pre>
	</dd>
</dl>
<h1 id="ATTRIBUTES">ATTRIBUTES</h1><p><a href="#TOP" class="toplink">Top</a></p>

<dl>
	<dt>Lorem</dt>
	<dd>
		<p>Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.</p>
	</dd>
	<dt>Ipsum</dt>
	<dd>
		<p>Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.</p>
	</dd>
	<dt>Dolor( $foo )</dt>
	<dd>
		<p>Lorem ipsum dolor sit amet consectueur .... elit. Sed diam nomumny.</p>
	</dd>
</dl>
<h1 id="ISSUES">ISSUES</h1><p><a href="#TOP" class="toplink">Top</a></p>

<h2 id="KNOWN_ISSUES">KNOWN ISSUES</h2>

<p>There are some issues known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny. SPACES&nbsp;&nbsp;&nbsp;ARE&nbsp;&nbsp;IMPORTANT</p>
<h2 id="UNKNOWN_ISSUES">UNKNOWN ISSUES</h2>

<p>There are also some issues not known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.</p>

</div></body>
);
}

sub cont_b {
return q{
<body>
<div class="pod">
<!-- INDEX START -->
<h3 id="TOP">Index</h3>
<ul>
	<li><a href="#NAME">NAME</a></li>
	<li><a href="#SYNOPSIS">SYNOPSIS</a><br />
<ul>
	<li><a href="#SUB_SYNOPSIS">SUB-SYNOPSIS</a></li>
</ul>
</li>
	<li><a href="#DESCRIPTION">DESCRIPTION</a></li>
	<li><a href="#LINKS">LINKS</a></li>
	<li><a href="#ISSUES">ISSUES</a><br />
<ul>
	<li><a href="#KNOWN_ISSUES">KNOWN ISSUES</a><br />
<ul>
	<li><a href="#ARGV">$ARGV</a></li>
	<li><a href="#ARGV-2">@ARGV</a></li>
	<li><a href="#ARGV-3">%ARGV</a></li>
	<li><a href="#Test_for_Escaped_HTML_in_Marked_text">Test for Escaped HTML in Marked text</a></li>
</ul>
</li>
</ul>
</li>
</ul>
<hr />
<!-- INDEX END -->

<h1 id="NAME">NAME</h1><p><a href="#TOP" class="toplink">Top</a></p>

<p>B - Some demo POD</p>
<h1 id="SYNOPSIS">SYNOPSIS</h1><p><a href="#TOP" class="toplink">Top</a></p>

<pre>	use Pod::Xhtml;
	my $px = new Pod::Xhtml;

</pre>
<h2 id="SUB_SYNOPSIS">SUB-SYNOPSIS</h2>

<p>To test returning back to head1.</p>
<h1 id="DESCRIPTION">DESCRIPTION</h1><p><a href="#TOP" class="toplink">Top</a></p>

<p>This is a module to translate POD to Xhtml. Lorem ipsum <b>Dolor</b> in <cite>Dolor</cite> sit amet consectueur adipscing elit. Sed diam nomumny.</p>
<h1 id="LINKS">LINKS</h1><p><a href="#TOP" class="toplink">Top</a></p>

<p><a href="#ARGV-2">@ARGV</a> should link to the as-yet undefined &quot;<i>@ARGV</i>&quot; section</p>
<p>Whereas <a href="#ARGV">$ARGV</a> shouldn't. It should link to the undefined
&quot;<i>$ARGV</i>&quot; section</p>
<h1 id="ISSUES">ISSUES</h1><p><a href="#TOP" class="toplink">Top</a></p>

<h2 id="KNOWN_ISSUES">KNOWN ISSUES</h2>

<h3 id="ARGV">$ARGV</h3>

<p>Is sometimes undefined</p>
<h3 id="ARGV-2">@ARGV</h3>

<p>Is occasionally populated with the numbers 1, 2, 3, 4, 5, 6, 7, 8, 9 and 10</p>
<h3 id="ARGV-3">%ARGV</h3>

<p>Does not exist</p>
<h3 id="Test_for_Escaped_HTML_in_Marked_text">Test for Escaped HTML in Marked text</h3>

<p><code>&lt;meta /&gt;</code></p>
<p><strong>R&amp;R</strong></p>
<p><i>&quot;hello&quot;</i></p>

</div></body>
};
}



sub readfile {
	my $filename = shift;
	local *IN;
	open(IN, '< ' . $filename) or die("Can't open $filename: $!");
	local $/ = undef;
	my $x = <IN>;
	close IN;
	return $x;
}

# Log::Trace stubs
sub TRACE {}
sub DUMP  {}

# this pod is for testing only!
__DATA__
=head1 NAME

A - Some demo POD

=head1 SYNOPSIS

	use Pod::Xhtml;
	my $px = new Pod::Xhtml;

=head1 DESCRIPTION

This is a module to translate POD to Xhtml. Lorem ipsum L<Dolor/Dolor> sit amet consectueur adipscing elit. Sed diam nomumny.
This is a module to translate POD to Xhtml. L<The Lorem entry|/Lorem> ipsum dolor sit amet
consectueur adipscing elit. Sed diam nomumny.
This is a module to translate F<POD> to Xhtml. B<Lorem> ipsum I<dolor> sit amet
C<consectueur adipscing> elit. X<Sed diam nomumny>.
This is a module to translate POD to Xhtml. See L</Lorem> ipsum dolor sit amet
consectueur adipscing elit. Sed diam L<nomumny>. L<http://foo.bar/baz/>

=head1 METHODS

=over 4

=item Nested blocks

Pod::Xhtml now supports nested over/item/back blocks:

=over 4

=item *

Point 1

=item *

Point Number 2

=item *

Item three

=item *

Point four

Still point four

  This is verbatim text in a bulleted list

=back

  This is verbatim test in a regular list

=back

=head1 ATTRIBUTES

=over 4

=item Lorem

Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=item Ipsum

Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=item Dolor( $foo )

Lorem ipsum dolor sit amet consectueur ..Z<adipscing>.. elit. Sed diam nomumny.

=back

=head1 ISSUES

=head2 KNOWN ISSUES

There are some issues known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny. S<SPACES   ARE  IMPORTANT>

=head2 UNKNOWN ISSUES

There are also some issues not known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=cut

