#!/usr/bin/perl -w

##
## sample usage:  perl convertToNifti.pl subjects.txt Dicom Nifti
##
##


# use module
use XML::Simple;
use Data::Dumper;
use Cwd 'realpath';
use Cwd;
use File::Spec;
use File::Find;
use File::Basename;
use File::Path;

my $logFile = '/Users/ntustison/Documents/Academic/InProgress/DeepVentNet/Scripts/Ventilation/ventilationUnetModelLog.txt';

open( FILE, "<$logFile" );
my @contents = <FILE>;
close( FILE );

my $csvFile = '/Users/ntustison/Documents/Academic/InProgress/DeepVentNet/Manuscript/ventilationUnetModelLog.csv';

open( FILE2, ">$csvFile" );
print FILE2 "Epoch,Training,Validation\n";

my $count = 1;
for( my $i = 0; $i < @contents; $i++ )
  {
  if( $contents[$i] =~ m/^30\/30/ )
    {
    my @tokens = split( ' - ', $contents[$i] );
    ( my $dice = ${tokens[2]} ) =~ s/loss:\ -//;
    ( my $val_dice = ${tokens[4]} ) =~ s/val_loss:\ -//;

    print FILE2 "$count,$dice,$val_dice\n";

    $count++;
    }
  }

close( FILE2 )  