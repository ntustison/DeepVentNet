library( ANTsR )
library( ANTsRNet )
library( keras )

keras::backend()$clear_session()

baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/'
dataDirectory <- paste0( baseDirectory, 'Data/' )
ventilationImageDirectory <- paste0( dataDirectory, 
  'Ventilation/Prediction/Images/' )
evaluationDirectory <- paste0( dataDirectory, 
  'Ventilation/Prediction/Evaluation/' )

classes <- c( "background", "defect/hypo", "normal" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Ventilation", "ForegroundMask" )
channelSize <- length( imageMods )

resampledSliceSize <- c( 128, 128 )
direction <- 3

unetModel <- createUnetModel2D( c( resampledImageSize, channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  layers = 1:4, lowestResolution = 32, dropoutRate = 0.2,
  convolutionKernelSize = c( 5, 5 ), deconvolutionKernelSize = c( 5, 5 ) )
load_model_weights_hdf5( unetModel, 
  filepath = paste0( dataDirectory, 'Ventilation/unetModel2DWeights.h5' ) )
unetModel %>% compile( loss = loss_multilabel_dice_coefficient_error,
  optimizer = optimizer_adam( lr = 0.0001 ),  
  metrics = c( multilabel_dice_coefficient ) )

ventilationImageFiles <- list.files( path = ventilationImageDirectory, 
  pattern = "*N4.nii.gz", full.names = TRUE )

predictionImageFiles <- list()
predictionSegmentationFiles <- list()

for( i in 1:length( ventilationImageFiles ) )
  {
  subjectId <- basename( ventilationImageFiles[i] )
  subjectId <- sub( "N4.nii.gz", '', subjectId )

  image <- antsImageRead( ventilationImageFiles[i], dimension = 3 )
  imageSize <- dim( image )
  mask <- antsImageRead( paste0( dataDirectory, 
    'Ventilation/Prediction/LungMasks/', subjectId, "Mask.nii.gz" ), dimension = 3 )

  numberOfSlices <- imageSize[direction]  
  originalSliceSize <- imageSize[-direction]

  batchX <- array( data = 0, dim = c( numberOfSlices, resampledSliceSize, channelSize ) )

  for( j in seq_len( numberOfSlices ) )
    {
    imageSlice <- extractSlice( image, j, direction )
    maskSlice <- extractSlice( mask, j, direction )
    if( any( originalSliceSize != resampledSliceSize ) )
      {
      imageSlice <- resampleImage( imageSlice, 
        resampledSliceSize, useVoxels = TRUE, interpType = 1 )
      maskSlice <- resampleImage( maskSlice, 
        resampledSliceSize, useVoxels = TRUE, interpType = 1 )
      }

    arrayImageSlice <- as.array( imageSlice ) 
    arrayImageSlice <- ( arrayImageSlice - mean( arrayImageSlice ) ) / 
      sd( arrayImageSlice )
    
    batchX[j,,,1] <- arrayImageSlice
    batchX[j,,,2] <- as.array( maskSlice )
    }
    
  predictedData <- unetModel %>% predict( batchX, verbose = 0 )
  probabilitySlices <- decodeUnet( predictedData, imageSlice )

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






