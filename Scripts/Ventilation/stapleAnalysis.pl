#!/usr/bin/perl -w


use File::Find;
use File::Basename;
use File::Path;

my $inputDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/';
#my $atroposDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/4DAnalysis/Vertex/ResultsMRF/';
# Performance 0
#      0.9562915  0.10971457  0.04370854  0.890285425
# Performance 1
#      0.93498625  0.14603211  0.06500428125  0.853209225
# Performance 2
#      0.955631725  0.1558357775  0.0443645285  0.8441304
# Performance 3
#      0.98784415  0.225721425  0.012155907175  0.774261575
#my $atroposDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/4DAnalysis/Vertex/ResultsMRF1/';
#Performance 0
#     0.97857585  0.240910755  0.02142417325  0.759089275
#Performance 1
#     0.929013075  0.1360943975  0.0709595085  0.8632169
#Performance 2
#     0.955113  0.1162868445  0.04488381825  0.883674
#Performance 3
#     0.984697325  0.1937196575  0.015302720925  0.806262125
#my $atroposDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/4DAnalysis/Vertex/ResultsMRF2/';
#Performance 0
#     0.953028525  0.106169415  0.0469714975  0.893830625
#Performance 1
#     0.9360642  0.146269025  0.06392873275  0.852963025
#Performance 2
#     0.955701725  0.160261265  0.0442946005  0.839705075
#Performance 3
#     0.988195225  0.2295322675  0.0118047338  0.770450775
#my $atroposDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/4DAnalysis/Vertex/ResultsMRF3/';
#Performance 0
#     0.951038875  0.1042283625  0.0489611875  0.895771625
#Performance 1
#     0.9368448  0.14629386925  0.063147905  0.8529444
#Performance 2
#     0.955757525  0.1631419725  0.04423870775  0.836824625
#Performance 3
#     0.988334725  0.23201461  0.011665228675  0.767968475
#my $atroposDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/4DAnalysis/Vertex/ResultsMRF4/';
#Performance 0
#     0.949918975  0.1035838425  0.0500809825  0.89641615
#Performance 1
#     0.9372211  0.14643343  0.06277171525  0.852809325
#Performance 2
#     0.955811875  0.1644978175  0.04418447675  0.835468875
#Performance 3
#     0.988396125  0.233403895  0.0116038648  0.766579125
#my $atroposDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/4DAnalysis/Vertex/ResultsMRF5/';
#Performance 0
#     0.949787575  0.1034898125  0.050212415  0.8965102
#Performance 1
#     0.937282725  0.1464316475  0.0627100865  0.852811825
#Performance 2
#     0.9558253  0.1647047225  0.044171058  0.835262
#Performance 3
#     0.98840855  0.2336178275  0.011591460075  0.7663652
my $atroposDirectory = '/Users/ntustison/Data/HeliumLungStudies/Vertex/VertexStudy/4DAnalysis/Vertex/ResultsMRF3/';



my @averages0 = (0, 0, 0, 0, 0);   # Atropos
my @averages1 = (0, 0, 0, 0, 0);   # Carlos
my @averages2 = (0, 0, 0, 0, 0);   # JAM
my @averages3 = (0, 0, 0, 0, 0);   # JG

my @averages = ( \@averages0, \@averages1, \@averages2, \@averages3 );

my $prefix = "";
my @timePoints = ();

open FILE, ">vdv.csv" or die $!;

for( my $i = 0; $i < 8; $i++ )
  {
  if( $i == 0 )
    {
    $prefix='VX770-025001';
    $timePoints[0] = '790';
    $timePoints[1] = '26';
    $timePoints[2] = '007';
    $timePoints[3] = '683';
    $timePoints[4] = '339';
    }
  elsif( $i == 1 )
    {
    $prefix='VX770-025002';
    $timePoints[0] = '18';
    $timePoints[1] = '788';
    $timePoints[2] = '526';
    $timePoints[3] = '241';
    $timePoints[4] = '072';
    }
  elsif( $i == 2 )
    {
    $prefix='VX770-025003';
    $timePoints[0] = '773';
    $timePoints[1] = '612';
    $timePoints[2] = '517';
    $timePoints[3] = '809';
    $timePoints[4] = '206';
    }
  elsif( $i == 3 )
    {
    $prefix='VX770-025004';
    $timePoints[0] = '944';
    $timePoints[1] = '667';
    $timePoints[2] = '046';
    $timePoints[3] = '172';
    $timePoints[4] = '426';
    }
  elsif( $i == 4 )
    {
    $prefix='VX770-025005';
    $timePoints[0] = '935';
    $timePoints[1] = '269';
    $timePoints[2] = '707';
    $timePoints[3] = '582';
    $timePoints[4] = '632';
    }
  elsif( $i == 5 )
    {
    $prefix='VX770-025006';
    $timePoints[0] = '148';
    $timePoints[1] = '817';
    $timePoints[2] = '136';
    $timePoints[3] = '125';
    $timePoints[4] = '387';
    }
  elsif( $i == 6 )
    {
    $prefix='VX770-025007';
    $timePoints[0] = '711';
    $timePoints[1] = '476';
    $timePoints[2] = '559';
    $timePoints[3] = '218';
    $timePoints[4] = '345';
    }
  elsif( $i == 7 )
    {
    $prefix='VX770-025008';
    $timePoints[0] = '233';
    $timePoints[1] = '003';
    $timePoints[2] = '800';
    $timePoints[3] = '019';
    $timePoints[4] = '015';
    }

  print "Processing $prefix\n";

  my $atropos4DResult = "${atroposDirectory}/${prefix}_atropos.nii.gz";

  my $localAtroposDir = "${inputDirectory}/AtroposScoring/DownsampledMRF/${prefix}-Resampled/";
  if( ! -e $localAtroposDir )
    {
    mkpath( $localAtroposDir );
    }

  for( my $j = 0; $j < @timePoints; $j++ )
    {
    print "  time point: $timePoints[$j]\n";

    my $atroposResult = "${localAtroposDir}/${timePoints[$j]}_atropos.nii.gz";

    `ExtractSliceFromImage 4 $atropos4DResult $atroposResult 3 $j`;
    `UnaryOperateImage 3 $atroposResult r 0 $atroposResult 1 2`;
    `UnaryOperateImage 3 $atroposResult r 0 $atroposResult 3 1`;
    `UnaryOperateImage 3 $atroposResult r 0 $atroposResult 4 1`;

    my @segmentations = ();

    $segmentations[0] = $atroposResult;
    $segmentations[1] = "${inputDirectory}/CarlosScoring/Downsampled/${prefix}-Resampled/${prefix}-${timePoints[$j]}_Carlos.nii.gz";
    $segmentations[2] = "${inputDirectory}/JAMScoring/Downsampled/${prefix}-Resampled/${timePoints[$j]}_jam.nii.gz";
    $segmentations[3] = "${inputDirectory}/JGScoring/Downsampled/${prefix}-Resampled/${timePoints[$j]}jg.nii.gz";

    my $size = `GetImageInformation 3 $segmentations[1] 2`;
    $size =~ s/\n|\r//g;
    `ResampleImage 3 $atroposResult $atroposResult $size 1 1`;
    `ChangeImageInformation 3 $atroposResult $atroposResult 4 $segmentations[1]`;

    my $lungMask = "${inputDirectory}/CarlosScoring/Downsampled/${prefix}-Resampled/${prefix}-${timePoints[$j]}_lungmask_resampled.nii.gz";
    `BinaryOperateImages 3 $atroposResult x $lungMask $atroposResult`;


    for( my $k = 0; $k < @segmentations; $k++ )
      {
      if( ! -e $segmentations[$k] )
        {
        print "Segmentation ${segmentations[$k]} does not exist\n.";
        exit 0;
        }
      }

#    for( my $k = 0; $k < @segmentations; $k++ )
#      {
#      my @volume = `CalculateVolumeFromBinaryImage 3 $segmentations[$k] 2`;
#      $volume[1] =~ s/\n|\r//g;
#      if( $k < @segmentations - 1 )
#        {
#        print FILE "${volume[1]},";
#        }
#      else
#        {
#        print FILE "${volume[1]}\n";
#        }
#      }


    my $count = 0;
    my @out = `STAPLEAnalysis 3 ${inputDirectory}/staple_${prefix}-${timePoints[$j]}.nii.gz @segmentations`;
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
      }
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



