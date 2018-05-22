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

# my $baseDir = '/Users/ntustison/Documents/Academic/InProgress/DeepVentNet/';
my $baseDir = '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/';

my $logFile = "${baseDir}Scripts/Proton/protonUnetModelLog.txt";

open( FILE, "<$logFile" );
my @contents = <FILE>;
close( FILE );

my $csvFile = "${baseDir}/Manuscript/protonUnetModelLog.csv";

open( FILE2, ">$csvFile" );
print FILE2 "Epoch,Dice,Val_Dice\n";

my $count = 1;
for( my $i = 0; $i < @contents; $i++ )
  {
  if( $contents[$i] =~ m/^16\/16/ )
    {
    my @tokens = split( ' - ', $contents[$i] );
    ( my $dice = ${tokens[2]} ) =~ s/loss:\ -//;
    ( my $val_dice = ${tokens[4]} ) =~ s/val_loss:\ -//;

    print FILE2 "$count,$dice,$val_dice\n";

    $count++;
    }
  }

close( FILE2 )  