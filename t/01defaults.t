#!/usr/bin/perl -w
#$Id: 01defaults.t,v 1.21 2006/07/12 12:00:39 mattheww Exp $

use strict;
use lib qw(./lib ../lib);
use Test;
use Pod::Xhtml;
use Getopt::Std;
use File::Basename;

getopts('tTs', \my %opt);
if ($opt{t} || $opt{T}) {
	require Log::Trace;
	import Log::Trace print => {Deep => $opt{T}};
}

chdir ( dirname ( $0 ) );

require Test_LinkParser;

my $filecont;
my $goodcont;

my $podia = 'a.pod';
my $podoa = 'a.pod.xhtml';
my $podga = 'a.xhtml';

unlink $podoa if -e $podoa;

plan tests => 17;

ok( $Pod::Xhtml::VERSION );

my $pod_links = Test_LinkParser->new();
my $parser = Pod::Xhtml->new(LinkParser => $pod_links);

#### try parsing from file
ok( ! -f $podoa );
$parser->parse_from_file( $podia, $podoa );
ok( -f $podoa );

$filecont = readfile( $podoa );
$goodcont = readfile( $podga );
DUMP("filecont", \$filecont);
ok( $filecont );
ok( $filecont =~ m/\Q$goodcont\E/ );
undef $filecont;
unlink $podoa unless $opt{s};

#### parsing from filehandles
ok( ! -f $podoa );
open(OUT, '>'.$podoa) or die("Can't open out $podoa: $!");
$parser->parse_from_filehandle( \*DATA, \*OUT );
close OUT;
ok( -f $podoa );

$filecont = readfile( $podoa );
DUMP("filecont", \$filecont);
ok( $filecont );
ok( $filecont =~ m/\Q$goodcont\E/ );
undef $filecont;
undef $goodcont;
unlink $podoa unless $opt{'s'};

my $podib = 'b.pod';
my $podob = 'b.pod.xhtml';
my $podgb = 'b.xhtml';
unlink $podob if -e $podob;
ok ( !-f $podob );
$parser->parse_from_file( $podib, $podob );
ok ( -f $podob );

$filecont = readfile( $podob );
$goodcont = readfile( $podgb );
DUMP("filecont", \$filecont);
ok( $filecont );
ok( $filecont =~ m/\Q$goodcont\E/ );
undef $filecont;
undef $goodcont;
unlink $podob unless $opt{'s'};

my $podic = "c.pod";
my $podoc = "c.pod.xhtml";
my $podgc = "c.xhtml";
unlink $podoc if -e $podoc;
ok ( ! -f $podoc );
$parser = Pod::Xhtml->new(LinkParser => $pod_links, MakeIndex => 2);
$parser->parse_from_file( $podic, $podoc );
ok ( -f $podoc );

$filecont = readfile( $podoc );
$goodcont = readfile( $podgc );
DUMP("filecont", \$filecont);
ok( $filecont );
ok( $filecont =~ m/\Q$goodcont\E/ );
undef $filecont;
undef $goodcont;
unlink $podoc unless $opt{'s'};

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

=head2 TOP

This should NOT reference #TOP, unless the top of the page has had its id
changed, somehow, for some reason.

=head2 EXAMPLE

This is the first example block.

=head1 ATTRIBUTES

=over 4

=item Lorem

Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=item Ipsum

Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=item Dolor( $foo )

Lorem ipsum dolor sit amet consectueur ..Z<>.. elit. Sed diam nomumny.

=back

=head2 EXAMPLE

This is the second example block.

=head1 ISSUES

=head2 KNOWN ISSUES

There are some issues known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny. S<SPACES   ARE  IMPORTANT>

=head2 UNKNOWN ISSUES

There are also some issues not known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=head3 EXAMPLE

This is the third example block.

=cut

