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
my $dataDirectory = "${baseDirectory}/Data/Proton/";

my @predictions = <${dataDirectory}/Prediction/JlfMasks/*Mask.nii.gz>;

my $csvFile = "${outputDirectory}/diceProtonJlf.csv";
open( FILE, ">${csvFile}" );

print FILE "ID,Whole,Left,Right,WholeCC,LeftCC,RightCC\n";

for( my $i = 0; $i < @predictions; $i++ )
  {
  my( $filename, $path, $suffix ) = fileparse( $predictions[$i] );
  ( my $subjectId = $filename ) =~ s/JlfMask\.nii\.gz//;
  print "$subjectId\n";   

  my $silverTruth = "${path}/../LungMasks/${subjectId}LungMask.nii.gz";
  if( ! -e $silverTruth )
    {
    print "Error:  $silverTruth does not exist.\n";
    exit;  
    }

  my $tmp = "${path}/${subjectId}SegmentationTmp.nii.gz";
  my $tmpCC = "${path}/${subjectId}SegmentationTmpCC.nii.gz";

  `ImageMath 3 $tmp ReplaceVoxelValue ${predictions[$i]} 1 1 3`;
  `ImageMath 3 $tmp ReplaceVoxelValue $tmp 2 2 1`;
  `ImageMath 3 $tmp ReplaceVoxelValue $tmp 3 3 2`;

  `ThresholdImage 3 $tmp $tmpCC 0 0 0 1`;
  `GetConnectedComponents 3 $tmpCC $tmpCC`;
  `ThresholdImage 3 $tmpCC $tmpCC 3 10000 0 1`;
  `ImageMath 3 $tmpCC m $tmpCC ${tmp}`;

  my @string = ( $subjectId );
  my @sources = ( $tmp, $tmpCC );
  for( my $j = 0; $j < @sources; $j++ )
    {
    my @out = `LabelOverlapMeasures 3 ${sources[$j]} $silverTruth`;
    
    my @stats = split( ' ', $out[2] );
    push( @string, $stats[2] );
    @stats = split( ' ', $out[5] );
    push( @string, $stats[3] );
    @stats = split( ' ', $out[6] );
    push( @string, $stats[3] );
    }
  my $subjectString = join( ',', @string );

  print FILE "${subjectString}\n";
  }
close( FILE );
