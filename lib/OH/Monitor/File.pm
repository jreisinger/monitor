package OH::Monitor::File;
use strict;
use warnings;
use Getopt::Std;
use Digest::SHA;
use File::Basename qw(basename dirname);
use YAML qw(Load);
use File::Find;

use Exporter qw(import);
our @EXPORT_OK = qw(check_integrity);

# we use this for prettier output later in _what_changed()
my @statnames = qw(dev ino mode nlink uid gid rdev
  size mtime ctime blksize blocks SHA-256);

# we store files' checksums (+ other info) here -- used by more subroutines
my $checksum_file = $ENV{HOME} . "/.monitor-checksum";

# load configuration from config file
sub _load_config {

    my $conf_file =
      dirname( $INC{'OH/Monitor/File.pm'} ) . '/../../../t/' . '.conf.yml';
    die "'$conf_file' problem: $!" unless -e $conf_file;
    my $content = eval { local ( @ARGV, $/ ) = ($conf_file); <>; };
    my $config = Load($content);

    return $config;
}

sub check_integrity {

    # get files to monitor
    my $config = _load_config();
    my @dirs   = @{ $config->{'sec-checks'}->{'monitor-dirs'} };
    my @files;
    no warnings "File::Find";    # don't report directories I can't cd into
    find( sub { push @files, $File::Find::name if -f && -r _ && !-l }, @dirs );

    _create_checksum( [@files] );

    my $rv = _check_checksum();
    if ($rv) {
        return $rv;
    } else {
        return 'ok';
    }
}

sub _create_checksum {
    my $files = shift;    # aref

    die "$checksum_file does not exist!" unless -e $checksum_file;
    die "$checksum_file has to have 600 permissions!"
      if ( ( stat($checksum_file) )[2] & 0777 ) & 066;

    # get already checksummed files
    my @checksummed_files;
    open my $fh_in, "<", $checksum_file or die "Can't open $checksum_file: $!";
    push @checksummed_files, ( split /\|/ )[0] while <$fh_in>;
    close $fh_in;

    open my $fh_out, ">>", $checksum_file
      or die "Can't open $checksum_file: $!";
    for my $file (@$files) {

        # skip already checksummed files
        next if grep { $file eq $_ } @checksummed_files;

        unless ( -f $file and -r _ ) {
            warn "Unable to stat file '$file': $!\n";
            next;
        }

        my $digest = Digest::SHA->new(256)->addfile( $file, 'p' )->hexdigest;
        print $fh_out $file, '|',
          join( '|', ( lstat($file) )[ 0 .. 7, 9 .. 12 ] ),
          "|$digest", "\n";
    }
    close $fh_out;
}

sub _check_checksum {

    # compare info on files from checksum_file with actual files info
    open my $CFILE, '<', $checksum_file
      or die "Unable to open check file $checksum_file:$!\n";

    my @changed;    # AoA
    while (<$CFILE>) {
        chomp;
        my @savedstats = split('\|');
        die "Wrong number of fields in line beginning with $savedstats[0]\n"
          unless ( scalar @savedstats == 14 );
        my @currentstats = ( lstat( $savedstats[0] ) )[ 0 .. 7, 9 .. 12 ];
        push( @currentstats,
            Digest::SHA->new(256)->addfile( $savedstats[0] )->hexdigest );

        if ( "@savedstats[1..13]" ne "@currentstats" ) {
            push @changed, _what_changed( \@savedstats, \@currentstats );
        }
    }

    close $CFILE;

    if (@changed) {
        return \@changed;
    } else {
        return;
    }
}

sub _what_changed {

    # iterates through attributes lists and prints any changes between
    # the two
    my ( $saved, $current ) = @_;

    # prints the name of the file after popping it off of the array read
    # from the check file
    my $output;
    $output .= shift( @{$saved} ) . ":\n";
    for ( my $i = 0 ; $i <= $#{$saved} ; $i++ ) {
        if ( $saved->[$i] ne $current->[$i] ) {
            $output .= "\t" . $statnames[$i] . ' is now ' . $current->[$i];
            $output .= " (should be " . $saved->[$i] . ")\n";
        }
    }
    return $output;
}
