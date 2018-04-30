library( ANTsR )
library( ANTsRNet )
library( keras )

keras::backend()$clear_session()

baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/'
dataDirectory <- paste0( baseDirectory, 'Data/' )
protonImageDirectory <- paste0( dataDirectory, 
  'Proton/Prediction/Images/' )
evaluationDirectory <- paste0( dataDirectory, 
  'Proton/Prediction/Evaluation/' )

classes <- c( "background", "leftLung", "rightLung" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Proton" )
channelSize <- length( imageMods )

resampledSliceSize <- c( 128, 128 )
direction <- 3

unetModel <- createUnetModel2D( c( resampledImageSize, channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  layers = 1:4 )
load_model_weights_hdf5( unetModel, 
  filepath = paste0( dataDirectory, 'Proton/unetModel2DWeights.h5' ) )
unetModel %>% compile( loss = loss_multilabel_dice_coefficient_error,
  optimizer = optimizer_adam( lr = 0.0001 ),  
  metrics = c( multilabel_dice_coefficient ) )

protonImageFiles <- list.files( path = protonImageDirectory, 
  pattern = "*Proton_N4Denoised.nii.gz", full.names = TRUE )

predictionImageFiles <- list()
predictionSegmentationFiles <- list()

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
    if( any( originalSliceSize != resampledSliceSize ) )
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
  probabilitySlices <- decodeUnet predictedData, imageSlice )

  for( j in seq_len( numberOfClassificationLabels ) )
    {
    probabilityArray <- array( data = 0, dim = imageSize )
    for( k in seq_len( numberOfSlices ) )  
      {
      probabilitySlice <- probabilitySlices[[k]][[j]]  
      if( any( originalSliceSize != resampledSliceSize ) )
        {
        probabilitySlice <- resampleImage( probabilitySlice, 
          originalSliceSize, useVoxels = TRUE, interpType = 1 )
        }
      probabilityArray[,,k] <- as.array( probabilitySlice )
      }
    probabilityImage <- as.antsImage( probabilityArray, reference = image )  

    imageFileName <- paste0( 
      evaluationDirectory, subjectId, "Probability", j, ".nii.gz" )

    cat( "Writing", imageFileName, "\n" )  
    antsImageWrite( probabilityImage, imageFileName )
    }  
  }






