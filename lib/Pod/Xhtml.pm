package Pod::Xhtml;

use strict;
use Pod::Parser;
use Pod::ParseUtils;
use vars qw/@ISA %COMMANDS %SEQ $VERSION/;

@ISA = qw(Pod::Parser);
($VERSION) = ('$Revision: 1.35 $' =~ m/([\d\.]+)/);

# recognized commands
%COMMANDS = map { $_ => 1 } qw(pod head1 head2 head3 head4 item over back for begin end);

# recognized special sequences
%SEQ = (
	B => \&seqB,
	C => \&seqC,
	E => \&seqE,
	F => \&seqF,
	I => \&seqI,
	L => \&seqL,
	S => \&seqS,
	X => \&seqX,
	Z => \&seqZ,
);


########## New PUBLIC methods for this class
sub asString { my $self = shift; return $self->{buffer}; }
sub asStringRef { my $self = shift; return \$self->{buffer}; }
sub addHeadText { my $self = shift; $self->{HeadText} .= shift; }
sub addBodyOpenText { my $self = shift; $self->{BodyOpenText} .= shift; }
sub addBodyCloseText { my $self = shift; $self->{BodyCloseText} .= shift; }

########## Override methods in Pod::Parser
########## PUBLIC INTERFACE
sub parse_from_file {
	my $self = shift;
	$self->resetMe;
	$self->SUPER::parse_from_file(@_);
}

sub parse_from_filehandle {
	my $self = shift;
	$self->resetMe;
	$self->SUPER::parse_from_filehandle(@_);
}

########## INTERNALS
sub initialize {
	my $self = shift;

	$self->{TopLinks} = qq(<p><a href="#TOP" class="toplink">Top</a></p>) unless defined $self->{TopLinks};
	$self->{MakeIndex} = 1 unless defined $self->{MakeIndex};
	$self->{MakeMeta} = 1 unless defined $self->{MakeMeta};
	$self->{FragmentOnly} = 0 unless defined $self->{FragmentOnly};
	$self->{HeadText} = $self->{BodyOpenText} = $self->{BodyCloseText} = '';
	$self->{LinkParser} ||= new Pod::Hyperlink;
	$self->SUPER::initialize();
}

sub command {
	my ($parser, $command, $paragraph, $line_num, $pod_para) = @_;
	my $ptree = $parser->parse_text( $paragraph, $line_num );
	$pod_para->parse_tree( $ptree );
	$parser->parse_tree->append( $pod_para );
}

sub verbatim {
	my ($parser, $paragraph, $line_num, $pod_para) = @_;
	$parser->parse_tree->append( $pod_para );
}

sub textblock {
	my ($parser, $paragraph, $line_num, $pod_para) = @_;
	my $ptree = $parser->parse_text( $paragraph, $line_num );
	$pod_para->parse_tree( $ptree );
	$parser->parse_tree->append( $pod_para );
}

sub end_pod {
	my $self = shift;
	my $ptree = $self->parse_tree;

	# clean up tree ready for parse
	foreach my $para (@$ptree) {
		if ($para->{'-prefix'} eq '=') {
			$para->{'TYPE'} = 'COMMAND';
		} elsif (! @{$para->{'-ptree'}}) {
			$para->{'-ptree'}->[0] = $para->{'-text'};
			$para->{'TYPE'} = 'VERBATIM';
		} else {
			$para->{'TYPE'} = 'TEXT';
		}
		foreach (@{$para->{'-ptree'}}) {
			unless (ref $_) { s/\n\s+$//; }
		}
	}

	# now loop over each para and expand any html escapes or sequences
	$self->_paraExpand( $_ ) foreach (@$ptree);
	$self->{buffer} =~ s/\n?<\/pre>(\s*)<pre>/$1/sg; # concatenate 'pre' blocks
	$self->{buffer} =~ s/<pre>\s+<\/pre>//sg;
	$self->{buffer} = $self->_makeIndex . $self->{buffer} if $self->{MakeIndex};
	$self->{buffer} = qq(<a name="TOP"></a>) . $self->{buffer};

	my $headblock = qq(<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\t<title>) . _htmlEscape( $self->{doctitle} ) . "</title>\n";
	$headblock .= $self->_makeMeta if $self->{MakeMeta};

	unless ($self->{FragmentOnly}) {
		$self->{buffer} = $headblock . $self->{HeadText} . "</head>\n<body>\n" . $self->{BodyOpenText} . $self->{buffer};
		$self->{buffer} .= $self->{BodyCloseText} . "</body>\n</html>\n";
	}

	# in stringmode we only accumulate the XHTML else we print it to the
	# filehandle
	unless ($self->{StringMode}) {
		my $out_fh = $self->output_handle;
		print $out_fh $self->{buffer};
	}
}

########## Everything else is PRIVATE
sub resetMe {
	my $self = shift;
	$self->{'-ptree'} = new Pod::ParseTree;
	$self->{'sections'} = [];
	$self->{'listKind'} = [];
	$self->{'listHasItems'} = [];

	foreach (qw(inList titleflag )) { $self->{$_} = 0; }
	foreach (qw(buffer doctitle)) { $self->{$_} = ''; }
}

sub parse_tree { return $_[0]->{'-ptree'}; }

sub _paraExpand {
	my $self = shift;
	my $para = shift;

	# collapse interior sequences and strings
	foreach ( @{$para->{'-ptree'}} ) { $_ = (ref $_) ? $self->_handleSequence($_) : _htmlEscape( $_ ); }

	# the parse tree has now been collapsed into a list of strings
	if ($para->{TYPE} eq 'TEXT') {
		$self->_addTextblock( join('', @{$para->{'-ptree'}}) );
	} elsif ($para->{TYPE} eq 'VERBATIM') {
		my $paragraph = join('', @{$para->{'-ptree'}});
		$self->{buffer} .= "<pre>$paragraph\n\n</pre>\n";
		if ($self->{titleflag} != 0) { $self->_setTitle( $paragraph ); warn "NAME followed by verbatim paragraph"; }
	} elsif ($para->{TYPE} eq 'COMMAND') {
		$self->_addCommand( $para->{'-name'}, join('', @{$para->{'-ptree'}}), $para->{'-line'} )
	} else {
		warn "Unrecognized paragraph type $para->{TYPE} found at $self->{_INFILE} line $para->{'-line'}\n";
	}
}

sub _addCommand {
	my $self = shift;
	my ($command, $paragraph, $line) = @_;

	unless (exists $COMMANDS{$command}) {
		warn "Unrecognized command '$command' skipped at $self->{_INFILE} line $line\n";
		return;
	}

	for ($command) {
		/^head1/ && do {
			my $anchor = $self->_addIndex( 'head1', $paragraph );
			$self->{buffer} .= qq(<h1><a name="$anchor"></a>$paragraph</h1>)
					.($self->{TopLinks} ? $self->{TopLinks} : '')."\n\n";
			if ($anchor eq 'NAME') { $self->{titleflag} = 1; }
			last;
		};
		/^head([234])/ && do {
			my $head_level = $1;
			my $anchor = $self->_addIndex( "head${head_level}", $paragraph );
			$self->{buffer} .= qq(<h${head_level}><a name="$anchor"></a>$paragraph</h${head_level}>\n\n);
			last;
		};
		/^item/ && do {
			unless ($self->{inList}) {
				warn "Not in list at $self->{_INFILE} line $line\n";
				last;
			}

			$self->{listHasItems}[-1] = 1;
			$self->{listCurrentParas}[-1] = 0;

			# is this the first item in the list?
			if (@{$self->{listKind}} && $self->{listKind}[-1] == 0) {
				if ($paragraph eq '*') {
					$self->{listKind}[-1] = 1;
					$self->{buffer} .= "<ul>\n";
				} else {
					$self->{listKind}[-1] = 2;
					$self->{buffer} .= "<dl>\n";
				}
			} else {
				# close last list item's tag#
				if ($self->{listKind}[-1] == 1) {
					$self->{buffer} .= "</li>\n";
				}
			}
			if (@{$self->{listKind}} && $self->{listKind}[-1] == 2) {
				$self->{buffer} .= qq(\t<dt>);
				if ($self->{MakeIndex} >= 2) {
					my $anchor = $self->_addIndex( 'list', $paragraph );
					$self->{buffer} .= qq(<a name="$anchor"></a>);
				}
				$self->{buffer} .= qq($paragraph</dt>\n);
			}
			last;
		};
		/^over/ && do {
			$self->{inList}++;
			push @{$self->{listKind}}, 0;
			push @{$self->{listHasItems}}, 0;
			push @{$self->{sections}}, 'OVER';
			push @{$self->{listCurrentParas}}, 0;
		};
		/^back/ && do {
			if (--$self->{inList} < 0) {
				warn "=back commands don't balance =overs at $self->{_INFILE} line $line\n";
				last;
			} elsif ($self->{listHasItems} == 0) {
				warn "empty list at $self->{_INFILE} line $line\n";
				last;
			} elsif (@{$self->{listKind}} && $self->{listKind}[-1] == 1) {
				$self->{buffer} .= "</li></ul>\n\n";
			} else {
				$self->{buffer} .= "</dl>\n\n";
			}
			push @{$self->{sections}}, 'BACK';
			pop  @{$self->{listHasItems}};
			pop  @{$self->{listKind}};
			pop  @{$self->{listCurrentParas}};
			last;
		};
		/^for/ || /^begin/ || /^end/ && do {
			warn "COMMAND $_ UNIMPLEMENTED AT THE MOMENT! at $self->{_INFILE} line $line\n";
			last;
		};
	}
}

sub _addTextblock {
	my $self = shift;
	my $paragraph = shift;

	if ($self->{titleflag} != 0) { $self->_setTitle( $paragraph ); }

	if (! @{$self->{listKind}} || $self->{listKind}[-1] == 0) {
		$self->{buffer} .= "<p>$paragraph</p>\n\n";
	} elsif (@{$self->{listKind}} && $self->{listKind}[-1] == 1) {
		if ($self->{listCurrentParas}[-1]++ == 0) {
			$self->{buffer} .= "\t<li>$paragraph";
		} else {
			$self->{buffer} .= "\n<br /><br />$paragraph";
		}
	} else {
		$self->{buffer} .= "\t\t<dd>$paragraph</dd>\n";
	}
}

# expand interior sequences recursively, bottom up
sub _handleSequence {
	my $self = shift;
	my $seq = shift;
	my $buffer = '';

	foreach (@{$seq->{'-ptree'}}) {
		if (ref $_) {
			$buffer .= $self->_handleSequence($_);
		} else {
			$buffer .= $_;
		}
	}

	unless (exists $SEQ{$seq->{'-name'}}) {
		warn "Unrecognized special sequence '$seq->{'-name'}' skipped at $self->{_INFILE} line $seq->{'-line'}\n";
		return $buffer;
	}
	return $SEQ{$seq->{'-name'}}->($self, $buffer);
}

sub _makeIndexName {
	my $arg = shift;

	$arg =~ s/&\w+?;/_/g;
	$arg = substr($arg, 0, 36);
	$arg =~ tr/a-zA-Z0-9_/_/c;
	return $arg;
}

sub _addIndex {
	my $self = shift;
	my ($type, $htmlarg) = @_;
	return unless defined $htmlarg;

	my $arg = _makeIndexName($htmlarg);
	push( @{$self->{sections}}, [$type, $arg, $htmlarg]);
	return $arg;
}

sub _makeIndex {
	my $self = shift;
	my $string = "<!-- INDEX START -->\n<h3>Index</h3>\n<ul>\n";
	foreach ( @{$self->{sections}} ) {
		if (ref $_) {
			my ($type, $href, $name) = @$_;
			my $index_link = qq(\t<li><a href="#${href}">${name}</a></li>);
			$index_link = qq(<ul>$index_link</ul>) unless ($type eq 'head1');
			$string .= $index_link;
		} elsif ($_ eq 'OVER') {
			$string .= qq(\t<ul>\n);
		} elsif ($_ eq 'BACK') {
			$string .= qq(\t</ul>\n);
		}
	}
	$string .= "</ul><hr />\n<!-- INDEX END -->\n\n";
	return $string;
}

sub _makeMeta {
	my $self = shift;
	return
		qq(\t<meta name="description" content="Pod documentation for ) . _htmlEscape( $self->{doctitle} ) . qq(" />\n)
		. qq(\t<meta name="inputfile" content=") . _htmlEscape( $self->input_file ) . qq(" />\n)
		. qq(\t<meta name="outputfile" content=") . _htmlEscape( $self->output_file ) . qq(" />\n)
		. qq(\t<meta name="created" content=") . _htmlEscape( scalar(localtime) ) . qq(" />\n)
		. qq(\t<meta name="generator" content="Pod::Xhtml $VERSION" />\n);
}

sub _setTitle {
	my $self = shift;
	my $paragraph = shift;

	if ($paragraph =~ m/^(.+?) - /) {
		$self->{doctitle} = $1;
	} elsif ($paragraph =~ m/^(.+?): /) {
		$self->{doctitle} = $1;
	} elsif ($paragraph =~ m/^(.+?)\.pm/) {
		$self->{doctitle} = $1;
	} else {
		$self->{doctitle} = substr($paragraph, 0, 80);
	}
	$self->{titleflag} = 0;
}

sub _htmlEscape {
	my $txt = shift;
	$txt =~ s/&/&amp;/g;
	$txt =~ s/</&lt;/g;
	$txt =~ s/>/&gt;/g;
	$txt =~ s/\"/&quot;/g;
	return $txt;
}

########## Sequence handlers
sub seqI { return '<i>' . $_[1] . '</i>'; }
sub seqB { return '<strong>' . $_[1] . '</strong>'; }
sub seqC { return '<code>' . $_[1] . '</code>'; }
sub seqF { return '<cite>' . $_[1] . '</cite>'; }
sub seqZ { return ''; }

sub seqL {
	my ($self, $link) = @_;
	$self->{LinkParser}->parse( $link );

	my $page = _htmlEscape( $self->{LinkParser}->page );
	my $kind = $self->{LinkParser}->type;
	my $string = '';

	if ($kind eq 'hyperlink') {	#easy, a hyperlink
		my $targ = _htmlEscape( $self->{LinkParser}->node );
		my $text = _htmlEscape( $self->{LinkParser}->text );
		$string = qq(<a href="$targ">$text</a>);
	} elsif ($page eq '') {	# a link to this page
		my $targ = _htmlEscape( _makeIndexName( $self->{LinkParser}->node ) );
		$string = $self->{LinkParser}->markup;
		$string =~ s|Q<(.+?)>|qq(<a href="#$targ">) . _htmlEscape( $1 ) . '</a>'|e;
	} elsif ($link !~ /\|/) {	# a link off-page with _no_ alt text
		$string = $self->{LinkParser}->markup;
		$string =~ s|Q<(.+?)>|'<b>' . _htmlEscape( $1 ) . '</b>'|e;
		$string =~ s|P<(.+?)>|'<cite>' . _htmlEscape( $1 ) . '</cite>'|e;
	} else {	# a link off-page with alt text
		my $text = _htmlEscape( $self->{LinkParser}->text );
		my $targ = _htmlEscape( $self->{LinkParser}->node );
		$string = "<b>$text</b> (";
		$string .= "<b>$targ</b> in " if $targ;
		$string .= "<cite>$page</cite>)";
	}
	return $string;
}

sub seqS {
	my $text = $_[1];
	$text =~ s/\s/&nbsp;/g;
	return $text;
}

sub seqX {
	my $self = shift;
	my $arg = shift;
	my $anchor = $self->_addIndex( 'head1', $arg );
	return qq[<a name="$anchor">$arg</a>];
}

sub seqE {
	my $self = shift;
	my $arg = shift;
	my $rv;

	if ($arg eq 'sol') {
		$rv = '/';
	} elsif ($arg eq 'verbar') {
		$rv = '|';
	} elsif ($arg =~ /^\d$/) {
		$rv = "&#$arg;";
	} elsif ($arg =~ /^0?x(\d+)$/) {
		$rv = $1;
	} else {
		$rv = "&$arg;";
	}
	return $rv;
}
1;
__END__

=head1 NAME

Pod::Xhtml - Generate well-formed XHTML documents from POD format documentation

=head1 SYNOPSIS

This module inherits from Pod::Parser, hence you can use this familiar
interface:

	use Pod::Xhtml;
	my $parser = new Pod::Xhtml;
	$parser->parse_from_file( $infile, $outfile );

	# or use filehandles instead
	$parser->parse_from_filehandle($in_fh, $out_fh);

	# or get the XHTML as a scalar
	my $parsertoo = new Pod::Xhtml( StringMode => 1 );
	$parsertoo->parse_from_file( $infile, $outfile );
	my $xhtml = $parsertoo->asString;

	# or get a reference to the XHTML string
	my $xhtmlref = $parsertoo->asStringRef;

	# to parse some other pod file to another output file all you need to do is...
	$parser->parse_from_file( $anotherinfile, $anotheroutfile );

There are options specific to Pod::Xhtml that you can pass in at construction
time, e.g.:

	my $parser = new Pod::Xhtml(StringMode => 1, MakeIndex => 0);

See L<"OPTIONS">. For more information also see L<Pod::Parser> which this
module inherits from.

=head1 DESCRIPTION

=over 4

=item new Pod::Xhtml( [ OPTIONS ] )

Create a new object. Optionally pass in some options in the form
C<'new Pod::Xhtml( StringMode =E<gt> 1);'>

=item $parser->parse_from_file( INPUTFILE, [OUTPUTFILE] )

Read POD from the input file, output to the output file (or STDOUT if no
file is given). See Pod::Parser docs for more.
Note that you can parse multiple files with the same object. All your options
will be preserved, as will any text you added with the add*Text methods.

=item $parser->parse_from_filehandle( [INPUTFILEHANDLE, [OUTPUTFILEHANDLE]] )

Read POD from the input filehandle, output to the output filehandle
(STDIN/STDOUT if no filehandle(s) given). See Pod::Parser docs for more.  Note
that you can parse multiple files with the same object. All your options will
be preserved, as will any text you added with the add*Text methods.

=item $parser->asString

Get the XHTML as a scalar. You'll probably want to use this with the
StringMode option.

=item $parser->asStringRef

As above, but you get a reference to the string, not the string itself.

=item $parser->addHeadText( $text )

Inserts some text just before the closing head tag. For example you can add a
link to a stylesheet. May be called many times to add lots of text. Note: you
need to call this some time B<before> any output is done, e.g. straight after
new(). Make sure that you only insert valid XHTML fragments.

=item $parser->addBodyOpenText( $text ) / $parser->addBodyCloseText( $text )

Inserts some text right at the beginning (or ending) of the body element. For
example you can add a navigation header and footer.  May be called many times
to add lots of text. Note: you need to call this some time B<before> any output
is done, e.g. straight after new(). Make sure that you only insert valid XHTML
fragments.

=back

=head1 OPTIONS

=over 4

=item StringMode

Default: 0. If set to 1 this does no output at all, even if filenames/handles
are supplied. Use asString or asStringRef to access the text if you set this
option.

=item MakeIndex

Default: 1. If set to 1 then an index of sections is created at the top of the
body. If set to 2 then the index includes non-bulleted list items

=item MakeMeta

Default: 1. If set to 1 then some meta tags are created, recording things like
input file, description, etc.

=item FragmentOnly

Default: 0. If 1, we only produce an XHTML fragment (suitable for use as a
server-side include etc). There is no HEAD element nor any BODY or HTML
tags. Any text added with the add*Text methods will B<not> be output.

=item TopLinks

At each section head this text is added to provide a link back to the top.
Set to 0 or '' to inhibit links, or define your own.

	Default: <p><a href="#TOP" class="toplink">Top</a></p>

=item LinkParser

An object that parses links in the POD document. By default, this is a regular
Pod::Hyperlink object. Any user-supplied link parser must conform the the
Pod::Hyperlink API.

=back

=head1 RATIONALE

There's Pod::PXML and Pod::XML, so why do we need Pod::Xhtml? You need an XSLT
to transform XML into XHTML and many people don't have the time or inclination
to do this. But they want to make sure that the pages they put on their web
site are well-formed, they want those pages to use stylesheets easily, and
possibly they want to squirt the XHTML through some kind of filter for more
processing.

By generating well-formed XHTML straight away we allow anyone to just use the
output files as-is. For those who want to use XML tools or transformations they
can use the XHTML as a source, because it's a well-formed XML document.

=head1 CAVEATS

This module outputs well-formed XHTML if the POD is well-formed. To check this
you can use something like:

	use Pod::Checker;
	my $syn = podchecker($defaultIn);

If $syn is 0 there are no syntax errors. If it's -1 then no POD was found. Any
positive number indicates that that number of errors were found. If the input
POD has errors then the output XHTML I<should> be well-formed but will probably
omit information, and in addition Pod::Xhtml will emit warnings. Note that
Pod::Parser seems to be sensitive to the current setting of $/ so ensure it's
the end-of-line character when the parsing is done.

=head1 AUTHOR

P Kent E<amp> Simon Flack  E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2004. This program is free software; you can redistribute it and/or
modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
