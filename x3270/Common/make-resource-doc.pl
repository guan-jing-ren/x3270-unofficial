#!/usr/bin/perl

use strict;

die "Must specify an argument.\n" unless ($#ARGV == 0);

# Figure out the version name.
my $version;
open VERSION, "<version.txt" or die "No version.txt file.\n";
while (<VERSION>) {
    chomp;
    if (/^version="(.*)"/) { $version=$1 }
}
close VERSION;

# Sort out the product, and %approd.
my %approd;
$approd{'a'} = 1;

if ($ARGV[0] eq "x3270") {
    $approd{'u'} = 1;
} elsif ($ARGV[0] eq "c3270") {
    $approd{'C'} = 1;
    $approd{'u'} = 1;
} elsif ($ARGV[0] eq "s3270") {
    $approd{'S'} = 1;
    $approd{'u'} = 1;
} elsif ($ARGV[0] eq "tcl3270") {
    $approd{'u'} = 1;
} elsif ($ARGV[0] eq "wc3270") {
    $approd{'C'} = 1;
    $approd{'w'} = 1;
} elsif ($ARGV[0] eq "ws3270") {
    $approd{'S'} = 1;
    $approd{'w'} = 1;
} else {
    die "Unknown product '$ARGV[0]'.\n";
}
my $product = $ARGV[0];
my $prefix = $product;
$prefix =~ s/3270//;
$approd{$prefix} = 1;
# Dump out %approd.
#foreach my $k (keys %approd) {
#    print STDERR "$k: $approd{$k}\n"
#}
my %types = (
    i => 'Integer',
    b => 'Boolean',
    s => 'String'
);

# Remove HTML attributes from a resource name.
sub nix
{
    my $txt = shift(@_);
    $txt =~ s/<\/?[\w.]+>//g;
    return $txt;
}

# The indices.
my @index;	# overall index
my @c_index;	# configuration index
my @a_index;	# appearance index
my @n_index;	# NVT-mode index
my @p_index;	# protocol index
my @i_index;	# interaction index
my @s_index;	# security index
my @t_index;	# tracing index
my @o_index;	# other index
my @d_index;	# deprecated index
my @indices = (
    \@c_index,
    \@a_index,
    \@n_index,
    \@p_index,
    \@i_index,
    \@s_index,
    \@t_index,
    \@o_index,
    \@d_index
);
my @index_name = (
    "Basic Configuration",
    "Appearance",
    "NVT-Mode",
    "Protocol",
    "Terminal Interaction",
    "Security",
    "Tracing",
    "Other",
    "Deprecated"
);

# The elements of an entry.
my $name;
my @names;
my $applies;
my $type;
my $default;
my @switch;
my @option;
my $description;
my $groups;

sub dump {
    if ($name && $applies) {
	# The minimum set of required attributes are type and description.
	die "$name missing type\n" if (!$type);
	die "$name missing description\n" if (!$description);
	foreach my $n (@names) {
	    # Add this name to the general index.
	    push @index, $n;
	    # Add this name to the specified indices...
	    if (defined($groups)) {
		foreach (split /\s+/, $groups) {
		    if ($_ eq "c") {
			push @c_index, $n;
		    } elsif ($_ eq "a") {
			push @a_index, $n;
		    } elsif ($_ eq "n") {
			push @n_index, $n;
		    } elsif ($_ eq "p") {
			push @p_index, $n;
		    } elsif ($_ eq "i") {
			push @i_index, $n;
		    } elsif ($_ eq "s") {
			push @s_index, $n;
		    } elsif ($_ eq "t") {
			push @t_index, $n;
		    } elsif ($_ eq "d") {
			push @d_index, $n;
		    } else {
			die "Unknown group '$_'\n";
		    }
		}
	    } else {
		# ... or to the 'other' index.
		push @o_index, $n;
	    }
	    my $tgt = nix($n);
	    print "<a name=\"$tgt\"></a>\n<b>Name:</b> $product.$n<br>\n";
	}

	print "<b>Type</b>: $type<br>\n";
	if ($default) { print "<b>Default</b>: $default<br>\n"; }
	if (defined(@switch)) {
	    my $comma;
	    print "<b>Command Line</b>:";
	    foreach my $s (@switch) {
		print "$comma $s\n";
		$comma = ",";
	    }
	    print "<br>\n";
	}
	if ($product eq "x3270") {
	    foreach my $o (@option) {
		print "<b>Option</b>: $o<br>\n";
	    }
	}
	$description =~ s/%p%/$product/g;
	while ($description =~ /%-([\w.<>\/*]+)%/) {
	    my $full = $1;
	    my $clean = nix($1);
	    $clean =~ s/<\/?i>//g;
	    $description =~ s/%-[\w.<>\/*]+%/<a href=#$clean>$product.$full<\/a>/;
	}
	#$description =~ s/%-([\w.]+)%/<a href=#\1><tt>$product.\1<\/tt><\/a>/g;
	print "<b>Description</b>:<br>\n";
	print "<p class=indented>$description</p>\n";
    }
    undef $name;
    undef @names;
    undef $applies;
    undef $type;
    undef $default;
    undef @switch;
    undef @option;
    undef $description;
    undef $groups;
}

print <<"EOS";
<!DOCTYPE doctype PUBLIC "-//w3c//dtd html 4.0 transitional//en">
<html>
<head>
 <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
 <title>$product Resources</title>
 <link HREF="http://www.w3.org/StyleSheets/Core/Steely" TYPE="text/css" REL="stylesheet">
 <style type="text/css">
<!--
.indented
{
    padding-left: 50pt;
    padding-right: 50pt;
}
-->
</style>
</head>
<body>
<h1>$product Resources</h1>
EOS

my $on = 1;
my $in_desc;
my $in_intro;
my @ifstack;
while (<STDIN>) {
    chomp;
    # Skip blank lines.
    next if (/^\s*$/);

    # Handle if/endif.
    if (/^if\s+(.*)/) {
	push @ifstack, $on;
	my $desc_applies;
	foreach (split /\s+/, $1) {
	    $desc_applies = 1 if ($approd{$_});
	}
	$on = $desc_applies if ($ifstack[$#ifstack]);
	next;
    } elsif (/^else/) {
	die "dangling else\n" if ($#ifstack < 0);
	$on = !$on if ($ifstack[$#ifstack]);
	next;
    } elsif (/^endif/) {
	die "dangling endif\n" if ($#ifstack < 0);
	$on = pop(@ifstack);
	next;
    }
    next unless $on;

    # Handle desc.
    if ($in_desc) {
	if (/^\./) {
	    undef $in_desc;
	} else {
	    $description .= $_ . "\n";
	}
	next;
    }

    # Handle intro.
    if (/^intro/) {
	$in_intro = 1;
	next;
    } elsif ($in_intro) {
	if (/^\./) {
	    undef $in_intro;
	    print "<h2>Alphabetical Resource List</h2>\n";
	} else {
	    s/%p%/$product/g;
	    while (/%-([\w.<>\/*]+)%/) {
		my $full = $1;
		my $clean = nix($1);
		$clean =~ s/<\/?i>//g;
		$_ =~ s/%-[\w.<>\/*]+%/<a href=#$clean>$product.$full<\/a>/;
	    }
	    print "$_\n";
	}
	next;
    }

    # Handle normal keywords.
    if (/name\s(.*)/) {
	&dump;
	@names = split /\s+/, $1;
	$name = $names[0];
	next;
    }
    if (/applies\s(.*)/) {
	undef $applies;
	foreach (split /\s+/, $1) {
	    $applies = 1 if ($approd{$_});
	}
	next;
    }
    if (/groups\s(.*)/) {
	$groups = $1;
	next;
    }
    if (/type\s([^\s]*)/) {
	$type = $types{$1};
	next;
    }
    if (/default\s(.*)/) {
	$default = $1;
	next;
    }
    if (/switch\s(.*)/) {
	push @switch, $1;
	next;
    }
    if (/option\s(.*)/) {
	push @option, $1;
	next;
    }
    if (/^desc/) {
	$in_desc = 1;
	next;
    }
    last if (/^EOF$/);
    die "Unknown keyword '$_'.\n";
}

&dump;

print <<EOT;
<h2>Index of All Resources</h2>
<table border cols=4 width="75%">
EOT
my $ix = 0;
foreach my $i (@index) {
    if (!($ix % 4)) {
	if ($ix) { print " </tr>\n"; }
	print "<tr>";
    }
    my $clean = nix($i);
    print " <td><a href=\"#$clean\">$i</a></td>";
    $ix++;
}
print " </tr>\n</table>\n";

my $q = 0;
foreach my $j (@indices) {
    my @arr = @$j;
    if ($#arr >= 0) {
	print "<h2>$index_name[$q] Resources</h2>\n";
	print "<table border cols=4 width=\"75%\">\n";
	my $ix = 0;
	foreach my $i (@arr) {
	    if (!($ix % 4)) {
		if ($ix) { print " </tr>\n"; }
		print "<tr>";
	    }
	    my $clean = nix($i);
	    print " <td><a href=\"#$clean\">$i</a></td>";
	    $ix++;
	}
	print " </tr>\n</table>\n";
    }
    $q = $q + 1;
}

print "<p><i>$product verson $version ", `date`, "\n";

print "</body>\n";
