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

$directory = '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/';

my @predictionProtons = ( <${directory}/Data/Proton/Prediction/Images/*N4Denoised.nii.gz> );
my $outputDirectory = "${directory}/Data/Proton/Prediction/JlfMasks/";

my $atlasDir = "${directory}/Data/Proton/Training/";
my @atlases = <${atlasDir}/Images/*N4Denoised.nii.gz>;
my @atlasSegs = <${atlasDir}/LungMasks/????LungMask.nii.gz>;
my @atlasBoundingBoxes = <${atlasDir}/LungMasks/????DilatedLungMask.nii.gz>;

my $numberOfSubjectSpecificAtlases = 10;

for( my $d = 0; $d < @predictionProtons; $d++ )
  {
  my $preprocessedH1 = $predictionProtons[$d];
  my ( $filename, $directory, $suffix ) = fileparse( $preprocessedH1, ".nii.gz" );
  ( my $subjectId = $filename ) =~ s/Proton_N4Denoised//;
  my $subjectMask = "${outputDirectory}/${subjectId}JlfMask.nii.gz";

  print "Doing $subjectId\n";

  my @atlasPrefixes = getSubjectSpecificAtlases2( \@atlases, \@atlasBoundingBoxes, $preprocessedH1, $numberOfSubjectSpecificAtlases );

  my @templates = ();
  my @templateMasks = ();

  for( my $t = 0; $t < @atlasPrefixes; $t++ )
    {
    my $atlas = "${atlasDir}/Images/${atlasPrefixes[$t]}Proton_N4Denoised.nii.gz";
    push( @templates, $atlas );
    my $mask = "${atlasDir}/LungMasks/${atlasPrefixes[$t]}LungMask.nii.gz";
    push( @templateMasks, $mask );
    }

  print "Processing $subjectId\n";
  print "@templates\n";

  my $paddedH1 = "${directory}/${filename}Padded.nii.gz";

  `ImageMath 3 $paddedH1 PadImage $preprocessedH1 10`;

  my @args = ( 'antsJointLabelFusion.sh', '-d', 3, '-q', 1, '-x', 'or',
                    '-k', 1,
                    '-c', 2,
                    '-j', 8,
                    '-y', 'b',
                    '-t', $paddedH1,
                    '-o', "${directory}/JLF/ants"
                );

  for( my $k = 0; $k < @templates; $k++ )
    {
    push( @args, '-g' );
    push( @args, $templates[$k] );
    push( @args, '-l' );
    push( @args, $templateMasks[$k] );
    }
  print "@args\n";
  system( @args ) == 0 || die "Error.\n";

  `cp ${directory}/JLF/antsLabels.nii.gz $subjectMask`;
  `rm -rf ${directory}/JLF/`;

  # de-pad

  `ImageMath 3 $subjectMask PadImage $subjectMask -10`;
  `ChangeImageInformation 3 $subjectMask $subjectMask 4 $preprocessedH1`;
  `BinaryMorphology 3 $subjectMask $subjectMask 5 1 0 1`;
  `BinaryMorphology 3 $subjectMask $subjectMask 5 1 0 2`;

  unlink( $paddedH1 );
  }


sub getSubjectSpecificAtlases2
{
  my ( $atlasesReference, $atlasBoundingBoxesReference, $target, $numberOfSubjectSpecificAtlases ) = @_;

  my @atlases = @{ $atlasesReference };
  my @atlasBoundingBoxes = @{ $atlasBoundingBoxesReference };

  my @distances = ();
  my @ids = ();

  for( my $i = 0; $i < @atlases; $i++ )
    {
    my ( $filename, $path, $suffix ) = fileparse( $atlases[$i], ".nii.gz" );
    ( my $id = $filename ) =~ s/Proton_N4Denoised//;
    print "   **** Checking atlas $id\n";

    my $outputPrefix = "${path}/${id}Tmp";

    my @args = ( "antsRegistration",
                    '-d', 3,
                    '-o', "[${outputPrefix},${outputPrefix}Warped.nii.gz]",
                    '-r', "[${atlases[$i]},$target,0]",
                    '-t', 'Translation[0.1]',
                    '-m', "CC[$atlases[$i],$target,1,3]",
                    '-c', 0,
                    '-f', 1,
                    '-s', 0
              );
    system( @args ) == 0 || die "Error: reg\n";

    my $warpedTarget = "${outputPrefix}Warped.nii.gz";
    my $outputAffine = "${outputPrefix}0GenericAffine.mat";

    my $similarity = `MeasureImageSimilarity -d 3 -m MI[${atlases[$i]},${warpedTarget},1,32,Regular,0.25] -x $atlasBoundingBoxes[$i]`;
    chomp( $similarity );

    unlink( $warpedTarget );
    unlink( $outputAffine );

    push( @distances, $similarity );
    push( @ids, $id );
    }

  my @sorted_indexes = sort { $distances[$a] <=> $distances[$b] } 0..$#distances;
  my @sorted_ids = @ids[@sorted_indexes];
  my @sorted_distances = @distances[@sorted_indexes];

  print "@sorted_ids\n";
  print "@sorted_distances\n";

  my @localTemplates = splice( @sorted_ids, 0, $numberOfSubjectSpecificAtlases );
  return @localTemplates;
}
