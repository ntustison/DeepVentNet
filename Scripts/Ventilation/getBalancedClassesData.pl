#/usr/bin/perl -w

use strict;

use Cwd 'realpath';
use File::Find;
use File::Basename;
use File::Path;
use File::Spec;
use List::Util 'shuffle';
use FindBin qw($Bin);

my $baseDirectory = '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/';
my $outputDirectory = "${baseDirectory}/Manuscript/";
my $dataDirectory = "${baseDirectory}/Data/Ventilation/";

my $unbalancedDirectory = "${dataDirectory}/Training/Images/Unbalanced/";

my @images = <${dataDirectory}/Training/Segmentations/*Segmentation2Class.nii.gz>;

my $count = 0;
for( my $i = 0; $i < @images; $i++ )
  {
  my( $filename, $path, $suffix ) = fileparse( $images[$i] );
  ( my $subjectId = $filename ) =~ s/Segmentation2Class\.nii\.gz//;
  print "$subjectId\n";   

  my @out = `LabelGeometryMeasures 3 $images[$i]`;

  my @stats1 = split( ' ', $out[1] );
  my $volume1 = $stats1[1];
  my @stats2 = split( ' ', $out[2] );
  my $volume2 = $stats2[1];

  my $ratio = $volume1 / ( $volume1 + $volume2 );

  if( $ratio > 0.3 && $ratio < 0.7 )
    {
    $count++;
    print "  ratio = $ratio\n";
    } 
  else
    { 
    # print "mv ${dataDirectory}/Training/Images/${subjectId}*.nii.gz $unbalancedDirectory\n";
    `mv ${dataDirectory}/Training/Images/${subjectId}*.nii.gz $unbalancedDirectory`;
    }
  }

print "Count = $count\n";