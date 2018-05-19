#!/usr/bin/perl -w


use File::Find;
use File::Basename;
use File::Path;

my $inputDirectory = '/Volumes/Untitled/VertexReaderStudy/StudyCases_processed/';
my $outputDirectory = '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/Data/Ventilation/Prediction/';

my @imageDirectories = <${inputDirectory}/UVa*>;

for( my $i = 0; $i < @imageDirectories; $i++ )
  {
  my @comps = split( '/', $imageDirectories[$i] );
  my $id = $comps[-1];
  print "$id\n";

  my @tmp = <${imageDirectories[$i]}/*/3He_atropos.nii.gz>;
  my $atroposSeg = $tmp[0];

  @tmp = <${imageDirectories[$i]}/*/3He_mask.lucia.nii.gz>;
  my $lungMask = $tmp[0];

  @tmp = <${imageDirectories[$i]}/*/3He_corrected.nii.gz>;
  my $corrected = $tmp[0];

  if( ! -e $atroposSeg )
    {
    die "Atropos doesn't exist\n";  
    }
  if( ! -e $lungMask )
    {
    die "Lung mask doesn't exist\n";  
    }
  if( ! -e $corrected )
    {
    die "Corrected doesn't exist\n";  
    }

  `cp $atroposSeg ${outputDirectory}/Segmentations/AtroposCases/${id}.atropos.nii.gz`;
  `cp $lungMask ${outputDirectory}/LungMasks/${id}_LungMask.nii.gz`;
  `cp $corrected ${outputDirectory}/Images/${id}_N4Corrected.nii.gz`;
  }