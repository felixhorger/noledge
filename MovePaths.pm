package MovePaths;

use strict;
use warnings;
use File::Spec::Functions 'abs2rel';
use Cwd 'realpath';

use Exporter;
our @ISA= qw( Exporter );
our @EXPORT_OK = qw( subroutine_for_find );
our @EXPORT = qw( static_file moved_file );

sub subroutine_for_find {
	# Get arguments
	# source and target realpaths
	my ($sourcename, $source, $target, $separators) = @_;
	# sourcename relative to source directory

	return sub {
		# Get paths
		my $name = $File::Find::name;
		(-f $name) or return;

		# Determine separators
		my ($start, $end) = &$separators($name);
		return unless (defined($start) and defined($end));

		# Read file
		my $code;
		{
			open(FH, "<", $name) or die "Could not open $name";
			read(FH, $code, -s FH);
			close(FH);
		}

		# Write correct paths
		{
			open(FH, ">", $name) or die "Could no write to $name";
			my $newcode;
			if (index($File::Find::dir, $source) == -1) {
				$newcode = static_file($sourcename, $source, $target, $code, $start, $end);
			}
			else {
				$newcode = moved_file($sourcename, $target, $code, $start, $end);
			}
			print(FH $newcode);
			close(FH);
		}
	}
}

sub moved_file {
	# Requires that wd is directory where $code lies
	# sourcename relative to source directory

	# Get arguments
	my ($sourcename, $target, $code, $start, $end) = @_;

	# Define pattern
	my $pattern = "${start}([^$start]*?$sourcename\\s*)$end";

	# Replace all paths
	my $newcode = "";
	my $i = 0;
	my $start_offset = length($start);
	my $end_offset = $start_offset + length($end);
	while ($code =~ /$pattern/g) {
		# Construct correct path
		my $adjusted = abs2rel(realpath($1), $target); 
		# Get parts of string that must be copied
		my $untouched_start = substr($code, $i, $-[0] - $i + $start_offset);
		my $untouched_end = substr($code, $-[0] + $start_offset + length($1), $end_offset);
		# Append to corrected code
		$newcode .= $untouched_start . $adjusted . $untouched_end;
		$i = $-[0] + $start_offset + length($1) + $end_offset;
	}
	# Copy until end of string
	$newcode .= substr($code, $i);

	return $newcode;
}

sub static_file {
	# Requires that wd is directory where $code lies

	# Get arguments
	my ($sourcename, $source, $target, $code, $start, $end) = @_;

	# Define pattern
	my $pattern = "${start}([^$start]*?$sourcename\\s*)$end";

	# Replace all paths
	my $newcode = "";
	my $i = 0;
	my $start_offset = length($start);
	my $end_offset = $start_offset + length($end);
	while ($code =~ /$pattern/g) {
		my $match_index = $-[0];
		# Get parts of string that must be copied
		my $untouched_start = substr($code, $i, $match_index - $i + $start_offset);
		my $untouched_end = substr($code, $match_index + $start_offset + length($1), $end_offset);
		# Construct correct path
		my $length_to_replace = length($1);
		my $path = realpath($1);
		unless ($path =~ s/$source/$target/g) {
			continue;
		}
		# Append to corrected code
		$newcode .= $untouched_start . abs2rel($path, $File::Fine::dir) . $untouched_end;
		$i = $match_index + $start_offset + $length_to_replace + $end_offset;
	}
	# Copy until end of string
	$newcode .= substr($code, $i);

	return $newcode;
}

1;

