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
# classes <- c( "background", "body", "leftLung", "rightLung" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Proton" )
channelSize <- length( imageMods )

resampledImageSize <- c( 128, 128, 64 )

unetModel <- createUnetModel3D( c( resampledImageSize, channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  layers = 1:4, lowestResolution = 16, dropoutRate = 0.2,
  convolutionKernelSize = c( 5, 5, 5 ), deconvolutionKernelSize = c( 5, 5, 5 ) )
load_model_weights_hdf5( unetModel, 
  filepath = paste0( dataDirectory, 'Proton/unetModelWeights.h5' ) )
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

  resampledImage <- resampleImage( image, resampledImageSize, 
    useVoxels = TRUE, interpType = 1 )
  resampledArray <- as.array( resampledImage )  

  batchX <- array( data = resampledArray, 
    dim = c( 1, resampledImageSize, channelSize ) )
    
  predictedData <- unetModel %>% predict( batchX, verbose = 0 )
  probabilityImagesArray <- decodeUnet( predictedData, image )

  for( j in seq_len( numberOfClassificationLabels ) )
    {
    imageFileName <- paste0( 
      evaluationDirectory, subjectId, "Probability", j, ".nii.gz" )

    cat( "Writing", imageFileName, "\n" )  
    antsImageWrite( resampleImage( probabilityImagesArray[[1]][[j]], 
      imageSize, useVoxels = TRUE, interpType = 1 ), imageFileName )  
    }  
  }






