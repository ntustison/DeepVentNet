#!/usr/bin/perl -w


use File::Find;
use File::Basename;
use File::Path;

my $inputDirectory = '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/Data/Ventilation/Prediction/';

my @images = <${inputDirectory}/Images/UVa*.nii.gz>;

my @averages0 = (0, 0, 0, 0, 0);   # Atropos
my @averages1 = (0, 0, 0, 0, 0);   # Carlos
my @averages2 = (0, 0, 0, 0, 0);   # Marta
my @averages3 = (0, 0, 0, 0, 0);   # Nick
my @averages4 = (0, 0, 0, 0, 0);   # unet

my @averages = ( \@averages0, \@averages1, \@averages2, \@averages3, \@averages4 );

my $csvFile = '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/Manuscript/ventilationStaple.csv';

open FILE, ">$csvFile" or die $!;

print FILE "ID,Rater,TotalLungDice,NormalLungDice,VentilationDefectDice\n";

for( my $i = 0; $i < @images; $i++ )
  {
  my ( $filename, $path, $suffix ) = fileparse( $images[$i], ".nii.gz" );
  ( my $id = $filename ) =~ s/_N4Corrected//;

  print "Processing $id\n";

  my @segmentations = ();

  my $segmentationDirectory = "${inputDirectory}/Segmentations/";
  $segmentations[0] = "${segmentationDirectory}/AtroposCases/${id}.atropos2Class.nii.gz";
  $segmentations[1] = "${segmentationDirectory}/CarlosCases/${id}.carlos.nii.gz";
  $segmentations[2] = "${segmentationDirectory}/MartaCases/${id}.marta.nii.gz";
  $segmentations[3] = "${segmentationDirectory}/NickCases/${id}.nick.nii.gz";
  $segmentations[4] = "${segmentationDirectory}/UnetCases/${id}.unet.nii.gz";

  my @segmentationNames = ( 'Atropos', 'Reader1', 'Reader2', 'Reader3', 'U-net' );

  my $count = 0;
  my $stapleSegmentation = "${segmentationDirectory}/StapleAnalysis/${id}.staple.nii.gz";
  my @out = `STAPLEAnalysis 3 $stapleSegmentation @segmentations`;
  print "@out\n";

  for( my $k = 0; $k < @segmentations; $k++ )
    {
    if( -e $segmentations[$k] )
      {
      my @confusion = split( ",", $out[$count] );
      $count++;
      $averages[$k][0]++;
      $averages[$k][1] += $confusion[4];
      $averages[$k][2] += $confusion[5];
      $averages[$k][3] += $confusion[7];
      $averages[$k][4] += $confusion[8];
      }
    my @string = ( $id, ${segmentationNames[$k]} );
    my @outDice = `LabelOverlapMeasures 3 $segmentations[$k] $stapleSegmentation`;
    my @stats = split( ' ', $outDice[2] );
    push( @string, $stats[2] );
    if( @outDice > 5 )
      {
      @stats = split( ' ', $outDice[5] );
      push( @string, $stats[3] );
      }
    else 
      {
      push( @string, 'NA' );
      }
    if( @outDice > 6 )  
      {
      @stats = split( ' ', $outDice[6] );
      push( @string, $stats[3] );
      }
    else 
      {
      push( @string, 'NA' );
      }

    my $subjectString = join( ',', @string );
    print FILE "${subjectString}\n";
    }
  }
close( FILE );

for( my $i = 0; $i < @averages; $i++ )
  {
  print "Performance $i\n";
  print "   ";
  for( my $j = 1; $j <= 4; $j++ )
    {
    my $measure = 0;
    if( $averages[$i][0] > 0 )
      {
      $measure = $averages[$i][$j] / $averages[$i][0];
      }
    print "  $measure";
    }
  print "\n";
  }



