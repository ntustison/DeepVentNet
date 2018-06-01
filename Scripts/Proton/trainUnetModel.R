library( ANTsR )
library( ANTsRNet )
library( keras )

keras::backend()$clear_session()

antsrnetDirectory <- '/Users/ntustison/Pkg/ANTsRNet/'
baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/'
source( paste0( baseDirectory, 'Scripts/unetBatchGenerator.R' ) )

classes <- c( "background", "leftLung", "rightLung" )

numberOfClassificationLabels <- length( classes )

imageMods <- c( "Proton" )
channelSize <- length( imageMods )

dataDirectory <- paste0( baseDirectory, 'Data/' )
protonImageDirectory <- paste0( dataDirectory, 
  'Proton/Training/Images/' )
protonImageFiles <- list.files( path = protonImageDirectory, 
  pattern = "*Proton_N4Denoised.nii.gz", full.names = TRUE )

templateDirectory <- paste0( dataDirectory, 'Proton/Training/Template/' )
reorientTemplateDirectory <- paste0( dataDirectory, 
  'Proton/Training/TemplateReorient/' )
reorientTemplate <- antsImageRead( 
  paste0( templateDirectory, "T_template0.nii.gz" ), dimension = 3 )

trainingImageFiles <- list()
trainingSegmentationFiles <- list()
trainingTransforms <- list()

cat( "Loading data...\n" )
pb <- txtProgressBar( min = 0, max = length( protonImageFiles ), style = 3 )

count <- 1
for( i in 1:length( protonImageFiles ) )
  {
  subjectId <- basename( protonImageFiles[i] )
  subjectId <- sub( "Proton_N4Denoised.nii.gz", '', subjectId )

  if( as.integer( subjectId ) >= 1033 && as.integer( subjectId ) <= 1084 )
    {
    # These are coronal images
    next;  
    }

  trainingImageFiles[[count]] <- protonImageFiles[i]
  trainingSegmentationFiles[[count]] <- paste0( dataDirectory,
    'Proton/Training/LungMasks/', subjectId, 
    "LungMask.nii.gz" )
  # trainingSegmentationFiles[[count]] <- paste0( dataDirectory,
  #   'Proton/Training/LobeMasks/', subjectId, 
  #   "LobeMask.nii.gz" )
  if( !file.exists( trainingSegmentationFiles[[count]] ) )
    {
    stop( paste( "Segmentation file", trainingSegmentationFiles[[count]], 
      "does not exist.\n" ) )
    }

  xfrmPrefix <- paste0( 'T_', subjectId )
  transformFiles <- list.files( templateDirectory, pattern = xfrmPrefix, full.names = TRUE ) 

  reorientTransform <- paste0( reorientTemplateDirectory, "TR_", subjectId, "0GenericAffine.mat" )

  fwdtransforms <- c()
  fwdtransforms[1] <- transformFiles[3]
  fwdtransforms[2] <- transformFiles[1]
  invtransforms <- c()
  invtransforms[1] <- reorientTransform
  invtransforms[2] <- transformFiles[1]
  invtransforms[3] <- transformFiles[2]

  if( !file.exists( fwdtransforms[1] ) || !file.exists( fwdtransforms[2] ) ||
      !file.exists( invtransforms[1] ) || !file.exists( invtransforms[2] ) ||
      !file.exists( invtransforms[3] ) )
    {
    stop( paste( "Transform", subjectId, "file does not exist.\n" ) )
    }

  trainingTransforms[[count]] <- list( 
    fwdtransforms = fwdtransforms, invtransforms = invtransforms )

  count <- count + 1  
  setTxtProgressBar( pb, i )
  }
cat( "\n" )  

###
#
# Create the Unet model
#

resampledImageSize <- dim( reorientTemplate )

unetModel <- createUnetModel3D( c( resampledImageSize, channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  numberOfLayers = 4, numberOfFiltersAtBaseLayer = 16, dropoutRate = 0.0,
  convolutionKernelSize = c( 7, 7, 5 ), deconvolutionKernelSize = c( 7, 7, 5 ) )

unetModel %>% compile( loss = loss_multilabel_dice_coefficient_error,
  optimizer = optimizer_adam( lr = 0.00001 ),  
  metrics = c( multilabel_dice_coefficient ) )

###
#
# Set up the training generator
#

batchSize <- 12L

# Split trainingData into "training" and "validation" componets for
# training the model.

numberOfData <- length( trainingImageFiles )
sampleIndices <- sample( numberOfData )

validationSplit <- floor( 0.8 * numberOfData )
trainingIndices <- sampleIndices[1:validationSplit]
numberOfTrainingData <- length( trainingIndices )
validationIndices <- sampleIndices[( validationSplit + 1 ):numberOfData]
numberOfValidationData <- length( validationIndices )

trainingData <- unetImageBatchGenerator$new( 
  imageList = trainingImageFiles[trainingIndices], 
  segmentationList = trainingSegmentationFiles[trainingIndices], 
  transformList = trainingTransforms[trainingIndices], 
  referenceImageList = trainingImageFiles, 
  referenceTransformList = trainingTransforms
  )

trainingDataGenerator <- trainingData$generate( batchSize = batchSize, 
  resampledImageSize = resampledImageSize, doRandomHistogramMatching = FALSE,
  referenceImage = reorientTemplate )

validationData <- unetImageBatchGenerator$new( 
  imageList = trainingImageFiles[validationIndices], 
  segmentationList = trainingSegmentationFiles[validationIndices], 
  transformList = trainingTransforms[validationIndices],
  referenceImageList = trainingImageFiles, 
  referenceTransformList = trainingTransforms
  )

validationDataGenerator <- validationData$generate( batchSize = batchSize,
  resampledImageSize = resampledImageSize, doRandomHistogramMatching = FALSE,
  referenceImage = reorientTemplate )

###
#
# Run training
#
track <- unetModel$fit_generator( 
  generator = reticulate::py_iterator( trainingDataGenerator ), 
  steps_per_epoch = ceiling( 3 * numberOfTrainingData / batchSize ),
  epochs = 200,
  validation_data = reticulate::py_iterator( validationDataGenerator ),
  validation_steps = ceiling( 3 * numberOfValidationData / batchSize ),
  callbacks = list( 
    callback_model_checkpoint( paste0( dataDirectory, "Proton/unetModelWeights.h5" ), 
      monitor = 'val_loss', save_best_only = TRUE, save_weights_only = TRUE,
      verbose = 1, mode = 'auto', period = 1 ),
     callback_reduce_lr_on_plateau( monitor = 'val_loss', factor = 0.1,
       verbose = 1, patience = 10, mode = 'auto' ),
     callback_early_stopping( monitor = 'val_loss', min_delta = 0.001, 
       patience = 20 )
  )
)  


