
=head1 MovePaths

Adjust relative paths in files which are to be moved to another location.

=cut


package MovePaths;

use strict;
use warnings;
use File::Spec::Functions 'abs2rel';
use Cwd 'realpath';

use Exporter;
our @ISA= qw( Exporter );
our @EXPORT_OK = qw( subroutine_for_find );
our @EXPORT = qw( static_file moved_file );



=over

=item subroutine_for_find(filename, source, target, separators)

Use this with File::find.

=over 8

=item filename: paths to be replaced point to this file in source.

=item source: moved from here (absolute).

=item target: to here (absolute).

=item separators: subroutine returning the separators enclosing paths.
It will be given the filename in which paths are to be adjusted.

=back

=cut

sub subroutine_for_find {
	# Get arguments
	my ($filename, $source, $target, $separators) = @_;
	# filename relative to source directory

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
				$newcode = static_file($filename, $source, $target, $code, $start, $end);
			}
			else {
				$newcode = moved_file($filename, $target, $code, $start, $end);
			}
			print(FH $newcode);
			close(FH);
		}
	}
}



=item moved_file(filename, target, code, start, end)

Adjust paths in the file that is being moved.
Working directory must be where the file is (where argument code is from).

=over 8

=item filename, target: see subroutine_for_find().

=item code: Contents of the file, where paths should be replaced.

=item start, end: path delimiters.

=back

=cut

sub moved_file {

	# Get arguments
	my ($filename, $target, $code, $start, $end) = @_;

	# Define pattern
	my $pattern = "${start}([^$start]*?$filename\\s*)$end";

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



=item static_file(filename, target, code, start, end)

Analogous to moved_file(), but for files that are not moved and
point to the file being moved.

=over 8

=item filename, target: see subroutine_for_find().

=item code: Contents of the file, where paths should be replaced.

=item start, end: path delimiters.

=back

=cut

sub static_file {
	# Get arguments
	my ($filename, $source, $target, $code, $start, $end) = @_;

	# Define pattern
	my $pattern = "${start}([^$start]*?$filename\\s*)$end";

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
		unless (defined($path) and $path =~ s/$source/$target/g) {
			next;
		}
		# Append to corrected code
		$newcode .= $untouched_start . abs2rel($path, $File::Find::dir) . $untouched_end;
		$i = $match_index + $start_offset + $length_to_replace + $end_offset;
	}
	# Copy until end of string
	$newcode .= substr($code, $i);

	return $newcode;
}


=back
=cut

1;

