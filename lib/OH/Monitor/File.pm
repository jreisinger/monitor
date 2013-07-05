package OH::File::Integrity;
use strict;
use warnings;
use Getopt::Std;
use Digest::SHA;

use Exporter qw(import);
our @EXPORT_OK = qw (check_f re_check_f);

# we use this for prettier output later in print_changed()
my @statnames = qw(dev ino mode nlink uid gid rdev
  size mtime ctime blksize blocks SHA-256);

# we store files' checksums (+ other info) here
my $progname = $0;
$progname =~ s/\.pl$//;
my $checksum_file = $ENV{HOME} . "/.$progname-checksum";    # Linux path

####################
sub check_f {
####################
    # create the checksum file (should be run only once)
    if ( -e $checksum_file ) {
        warn "'$checksum_file' already exists!\n";
        return 1;
    }
    my @files = @_;
    open my $fh, ">>", $checksum_file or die "Can't open $checksum_file: $!";
    for my $file (@files) {
        unless ( -e $file ) {
            warn "Unable to stat file '$file': $!\n";
            next;
        }
        my $digest = Digest::SHA->new(256)->addfile( $file, 'p' )->hexdigest;
        print $fh $file, '|',
          join( '|', ( lstat($file) )[ 0 .. 7, 9 .. 12 ] ),
          "|$digest", "\n";
    }
    close $fh;
}

####################
sub re_check_f {
####################
    # compare info on files from checksum_file with actual files info
    open my $CFILE, '<', $checksum_file
      or die "Unable to open check file $checksum_file:$!\n";
    while (<$CFILE>) {
        chomp;
        my @savedstats = split('\|');
        die "Wrong number of fields in line beginning with $savedstats[0]\n"
          unless ( scalar @savedstats == 14 );
        my @currentstats = ( lstat( $savedstats[0] ) )[ 0 .. 7, 9 .. 12 ];
        push( @currentstats,
            Digest::SHA->new(256)->addfile( $savedstats[0] )->hexdigest );

        # print the changed fields only if something has changed
        print_changed( \@savedstats, \@currentstats )
          if ( "@savedstats[1..13]" ne "@currentstats" );
    }
    close $CFILE;
}

####################
sub print_changed {
####################
    # iterates through attributes lists and prints any changes between
    # the two
    my ( $saved, $current ) = @_;

    # prints the name of the file after popping it off of the array read
    # from the check file
    print shift @{$saved}, ":\n";
    for ( my $i = 0 ; $i <= $#{$saved} ; $i++ ) {
        if ( $saved->[$i] ne $current->[$i] ) {
            print "\t" . $statnames[$i] . ' is now ' . $current->[$i];
            print " (should be " . $saved->[$i] . ")\n";
        }
    }
}
