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
templateDirectory <- paste0( dataDirectory, 'Proton/Training/Template/' )

reorientTemplateDirectory <- paste0( dataDirectory, 
  'Proton/Prediction/TemplateReorient/' )
reorientTemplate <- antsImageRead( 
  paste0( templateDirectory, "T_template0.nii.gz" ), dimension = 3 )

classes <- c( "background", "leftLung", "rightLung" )
# classes <- c( "background", "body", "leftLung", "rightLung" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Proton" )
channelSize <- length( imageMods )

resampledImageSize <- dim( reorientTemplate )

unetModel <- createUnetModel3D( c( resampledImageSize, channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  numberOfLayers = 4, numberOfFiltersAtBaseLayer = 16, dropoutRate = 0.0,
  convolutionKernelSize = c( 5, 5, 5 ), deconvolutionKernelSize = c( 5, 5, 5 ) )
load_model_weights_hdf5( unetModel, 
  filepath = paste0( dataDirectory, 'Proton/unetModelWeights.h5' ) )
unetModel %>% compile( loss = loss_multilabel_dice_coefficient_error,
  optimizer = optimizer_adam( lr = 0.000001 ),  
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

  # resampledImage <- resampleImage( image, resampledImageSize, 
  #   useVoxels = TRUE, interpType = 1 )

  reorientTransform <- paste0( reorientTemplateDirectory, "TR_", 
    subjectId, "0GenericAffine.mat" )
  resampledImage <- antsApplyTransforms( reorientTemplate, image, 
    interpolator = "linear", transformlist = c( reorientTransform ),
    whichtoinvert = c( FALSE )  )

  resampledArray <- as.array( resampledImage )  
  batchX <- array( data = resampledArray, 
    dim = c( 1, resampledImageSize, channelSize ) )

  batchX <- ( batchX - mean( batchX ) ) / sd( batchX )
    
  predictedData <- unetModel %>% predict( batchX, verbose = 0 )
  probabilityImagesArray <- decodeUnet( predictedData, reorientTemplate )

  for( j in seq_len( numberOfClassificationLabels ) )
    {
    imageFileName <- paste0( 
      evaluationDirectory, subjectId, "Probability", j, ".nii.gz" )

    cat( "Writing", imageFileName, "\n" )  

    probabilityImage <- antsApplyTransforms( image, 
      probabilityImagesArray[[1]][[j]], interpolator = "linear", 
      transformlist = c( reorientTransform ), whichtoinvert = c( TRUE ) )

    antsImageWrite( probabilityImage, imageFileName )  
    }  
  }






