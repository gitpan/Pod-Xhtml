#!/usr/bin/perl -w
#$Id: 01defaults.t,v 1.11 2004/10/21 16:57:02 simonf Exp $

use strict;
use lib qw(./lib ../lib);
use Test;
use Pod::Xhtml;

if (-d 't') {
	chdir( 't' );
}
require Test_LinkParser;

my $filecont;
my $podia = 'a.pod';
my $podoa = 'a.xhtml';

unlink $podoa if -e $podoa;

plan tests => 9;

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
unlink $podoa;



sub cont_a {
return q{
<body>
<a name="TOP"></a><!-- INDEX START -->
<h3>Index</h3>
<ul>
	<li><a href="#NAME">NAME</a></li>	<li><a href="#SYNOPSIS">SYNOPSIS</a></li>	<li><a href="#DESCRIPTION">DESCRIPTION</a></li>	<li><a href="#Sed_diam_nomumny">Sed diam nomumny</a></li>	<li><a href="#METHODS">METHODS</a></li>	<ul>
	<ul>
	</ul>
	</ul>
	<li><a href="#ATTRIBUTES">ATTRIBUTES</a></li>	<ul>
	</ul>
	<li><a href="#ISSUES">ISSUES</a></li><ul>	<li><a href="#KNOWN_ISSUES">KNOWN ISSUES</a></li></ul><ul>	<li><a href="#UNKNOWN_ISSUES">UNKNOWN ISSUES</a></li></ul></ul><hr />
<!-- INDEX END -->

<h1><a name="NAME"></a>NAME</h1><p><a href="#TOP" class="toplink">Top</a></p>

<p>A - Some demo POD</p>

<h1><a name="SYNOPSIS"></a>SYNOPSIS</h1><p><a href="#TOP" class="toplink">Top</a></p>

<pre>	use Pod::Xhtml;
	my $px = new Pod::Xhtml;

</pre>
<h1><a name="DESCRIPTION"></a>DESCRIPTION</h1><p><a href="#TOP" class="toplink">Top</a></p>

<p>This is a module to translate POD to Xhtml. Lorem ipsum <b>Dolor</b> in <cite>Dolor</cite> sit amet consectueur adipscing elit. Sed diam nomumny.
This is a module to translate POD to Xhtml. <a href="#Lorem">The Lorem entry</a> ipsum dolor sit amet
consectueur adipscing elit. Sed diam nomumny.
This is a module to translate <cite>POD</cite> to Xhtml. <strong>Lorem</strong> ipsum <i>dolor</i> sit amet
<code>consectueur adipscing</code> elit. <a name="Sed_diam_nomumny">Sed diam nomumny</a>.
This is a module to translate POD to Xhtml. See <a href="#Lorem">Lorem</a> ipsum dolor sit amet
consectueur adipscing elit. Sed diam <cite>nomumny</cite>. <a href="http://foo.bar/baz/">http://foo.bar/baz/</a></p>

<h1><a name="METHODS"></a>METHODS</h1><p><a href="#TOP" class="toplink">Top</a></p>

<dl>
	<dt>Nested blocks</dt>
		<dd>Pod::Xhtml now supports nested over/item/back blocks:</dd>
<ul>
	<li>Point 1</li>
	<li>Point Number 2</li>
	<li>Item three</li>
	<li>Point four
<br /><br />Still point four</li></ul>

</dl>

<h1><a name="ATTRIBUTES"></a>ATTRIBUTES</h1><p><a href="#TOP" class="toplink">Top</a></p>

<dl>
	<dt>Lorem</dt>
		<dd>Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.</dd>
	<dt>Ipsum</dt>
		<dd>Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.</dd>
	<dt>Dolor( $foo )</dt>
		<dd>Lorem ipsum dolor sit amet consectueur .... elit. Sed diam nomumny.</dd>
</dl>

<h1><a name="ISSUES"></a>ISSUES</h1><p><a href="#TOP" class="toplink">Top</a></p>

<h2><a name="KNOWN_ISSUES"></a>KNOWN ISSUES</h2>

<p>There are some issues known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny. SPACES&nbsp;&nbsp;&nbsp;ARE&nbsp;&nbsp;IMPORTANT</p>

<h2><a name="UNKNOWN_ISSUES"></a>UNKNOWN ISSUES</h2>

<p>There are also some issues not known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.</p>

</body>
};
}

sub readfile {
	my $filename = shift;
	open(IN, '<' . $filename) or die("Can't open $filename: $!");
	local $/ = undef;
	my $x = <IN>;
	close IN;
	return $x;
}

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

=back

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

