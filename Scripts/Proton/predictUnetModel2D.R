library( ANTsR )
library( keras )

keras::backend()$clear_session()

antsrnetDirectory <- '/Users/ntustison/Pkg/ANTsRNet/'
modelDirectory <- paste0( antsrnetDirectory, 'Models/' )
baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/'

source( paste0( modelDirectory, 'createUnetModel.R' ) )
source( paste0( modelDirectory, 'unetUtilities.R' ) )

classes <- c( "background", "leftLung", "rightLung" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Proton" )
channelSize <- length( imageMods )

resampledSliceSize <- c( 128, 128 )
direction <- 3
unetModel <- load_model_hdf5( paste0( dataDirectory, "Proton/unetModel2D.h5" )

dataDirectory <- paste0( baseDirectory, 'Data/' )
protonImageDirectory <- paste0( dataDirectory, 
  'Proton/Prediction/Images/' )
evaluationDirectory <- paste0( dataDirectory, 
  'Proton/Prediction/Evaluation/' )
  
protonImageFiles <- list.files( path = protonImageDirectory, 
  pattern = "*Proton_N4Denoised.nii.gz", full.names = TRUE )

predictionImageFiles <- list()
predictionSegmentationFiles <- list()

count <- 1
for( i in 1:length( protonImageFiles ) )
  {
  subjectId <- basename( protonImageFiles[i] )
  subjectId <- sub( "Proton_N4Denoised.nii.gz", '', subjectId )

  image <- antsImageRead( protonImageFiles[i], dimension = 3 )
  imageSize <- dim( image )

  numberOfSlices <- imageSize[direction]  
  originalSliceSize <- imageSize[-direction]

  batchX <- array( data = 0, dim = c( numberOfSlices, resampledSliceSize, 1 ) )

  for( j in seq_len( numberOfSlices ) )
    {
    imageSlice <- extractSlice( image, j, direction )
    if( any( originalSliceSize != resampledSliceSize ) ) )
      {
      imageSlice <- resampleImage( imageSlice, 
        resampledSliceSize, useVoxels = TRUE, interpType = 1 )
      }

    arraySlice <- as.array( imageSlice ) 
    arraySlice <- ( arraySlice - min( arraySlice ) ) / 
      ( max( arraySlice ) - min( arraySlice ) )
    
    batchX[j,,,1] <- arraySlice
    }
    
  predictedData <- unetModel %>% predict( batchX, verbose = 0 )
  probabilitySlices <- decodeY( predictedData, imageSlice )

  for( j in seq_len( numberOfClassificationLabels ) )
    {
    probabilityArray <- array( data = 0, dim = imageSize )
    for( k in seq_len( numberOfSlices ) )  
      {
      probabilityArray[k,,] <- as.array( probabilitySlices[[i]][[j]] )
      }
    probabilityImage <- as.antsImage( probabilityArray, reference = image )  

    imageFileName <- paste0( 
      evaluationDirectory, subjectId, "Probability", j, ".nii.gz" )
    antsImageWrite( probabilityImage, imageFileName )
    }  
  }






