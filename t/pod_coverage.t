use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD Coverage" if $@;

# Methods documented in Pod::Parser
my @pod_parser = map "^$_\$",
	qw(command initialize end_pod textblock verbatim parse_tree);

# Private methods
my @private = map "^$_\$", qw(resetMe seq[A-Z]);
all_pod_coverage_ok({also_private => [ qr/^[A-Z_]+$/, @private, @pod_parser ]});
