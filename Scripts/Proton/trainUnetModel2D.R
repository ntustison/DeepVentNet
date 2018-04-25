library( ANTsR )
library( keras )

keras::backend()$clear_session()

antsrnetDirectory <- '/Users/ntustison/Pkg/ANTsRNet/'
modelDirectory <- paste0( antsrnetDirectory, 'Models/' )
baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/'

source( paste0( modelDirectory, 'createUnetModel.R' ) )
source( paste0( modelDirectory, 'unetUtilities.R' ) )
source( paste0( baseDirectory, 'Scripts/unetBatchGenerator2D.R' ) )

classes <- c( "background", "leftLung", "rightLung" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Proton" )
channelSize <- length( imageMods )

dataDirectory <- paste0( baseDirectory, 'data/' )
trainingImageDirectory <- paste0( dataDirectory, 
  'Proton/Images/' )
trainingImageFiles <- list.files( path = trainingImageDirectory, 
  pattern = "*Proton_N4Denoised.nii.gz", full.names = TRUE )
templateDirectory <- paste0( dataDirectory, 'Proton/Template/' )

trainingSegmentationFiles <- list()
trainingTransforms <- list()

for( i in 1:length( trainingImageFiles ) )
  {
  subjectId <- basename( trainingImageFiles[i] )
  subjectId <- sub( "Proton_N4Denoised.nii.gz", '', subjectId )

  trainingSegmentationFiles[[i]] <- paste0( dataDirectory,
    'Proton/LungMasks/', subjectId, 
    "LungMask.nii.gz" )
  if( !file.exists( trainingSegmentationFiles[[i]] ) )
    {
    stop( paste( "Segmentation file", trainingSegmentationFiles[[i]], 
      "does not exist.\n" ) )
    }

  xfrmPrefix <- paste0( 'T_', subjectId )
  transformFiles <- list.files( templateDirectory, pattern = xfrmPrefix, full.names = TRUE ) 

  fwdtransforms <- c()
  fwdtransforms[1] <- transformFiles[3]
  fwdtransforms[2] <- transformFiles[1]
  invtransforms <- c()
  invtransforms[1] <- transformFiles[1]
  invtransforms[2] <- transformFiles[2]

  if( !file.exists( fwdtransforms[1] ) || !file.exists( fwdtransforms[2] ) ||
      !file.exists( invtransforms[1] ) || !file.exists( invtransforms[2] ) )
    {
    stop( "Transform file does not exist.\n" )
    }

  trainingTransforms[[i]] <- list( 
    fwdtransforms = fwdtransforms, invtransforms = invtransforms )
  }

###
#
# Create the Unet model
#

paddedImageSize <- c( 256, 256, 256 )

direction <- 3

unetModel <- createUnetModel2D( c( paddedImageSize[-direction], channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  layers = 1:4 )

unetModel %>% compile( loss = loss_multilabel_dice_coefficient_error,
  optimizer = optimizer_adam( lr = 0.0001 ),  
  metrics = c( multilabel_dice_coefficient ) )

###
#
# Set up the training generator
#

batchSize <- 32L

# Split trainingData into "training" and "validation" componets for
# training the model.

numberOfTrainingData <- length( trainingImageFiles )
sampleIndices <- sample( numberOfTrainingData )

validationSplit <- floor( 0.9 * length( numberOfTrainingData ) )
trainingIndices <- sampleIndices[1:validationSplit]
validationIndices <- sampleIndices[( validationSplit + 1 ):batchSize]

trainingData <- unetImageBatchGenerator2D$new( 
  imageList = trainingImageFiles[trainingIndices], 
  segmentationList = trainingSegmentationFiles[trainingIndices], 
  transformList = trainingTransforms[trainingIndices], 
  referenceImageList = trainingImageFiles, 
  referenceTransformList = trainingTransforms )

trainingDataGenerator <- trainingData$generate( batchSize = batchSize,
  direction = direction, sliceSamplingRate = 0.2,
  paddedSize = paddedImageSize[-direction] )

validationData <- unetImageBatchGenerator2D$new( 
  imageList = trainingImageFiles[validationIndices], 
  segmentationList = trainingSegmentationFiles[validationIndices], 
  transformList = trainingTransforms[validationIndices], 
  referenceImageList = trainingImageFiles, 
  referenceTransformList = trainingTransforms )

validationDataGenerator <- trainingData$generate( batchSize = batchSize,
  direction = direction, sliceSamplingRate = 0.2,
  paddedSize = paddedImageSize[-direction] )

###
#
# Run training
#

track <- unetModel$fit_generator( 
  generator = reticulate::py_iterator( trainingDataGenerator ), 
  steps_per_epoch = 50, #ceiling( 400 / batchSize ),
  epochs = 40,
  validation_data = reticulate::py_iterator( validationDataGenerator ),
  validation_steps = ceiling( 100 / batchSize ),
  callbacks = list( 
    callback_model_checkpoint( paste0( dataDirectory, "Proton/unetModel2D.h5" ), 
      monitor = 'val_loss', save_best_only = TRUE, save_weights_only = FALSE,
      verbose = 1, mode = 'auto', period = 1 )
    # callback_early_stopping( monitor = 'val_loss', min_delta = 0.001, 
    #   patience = 10 ),
    # callback_reduce_lr_on_plateau( monitor = 'val_loss', factor = 0.5,
    #   patience = 0, epsilon = 0.001, cooldown = 0 )
                  # callback_early_stopping( patience = 2, monitor = 'loss' ),
    )
  )







