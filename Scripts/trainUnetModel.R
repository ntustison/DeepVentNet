library( ANTsR )
library( keras )

keras::backend()$clear_session()

antsrnetDirectory <- '/Users/ntustison/Pkg/ANTsRNet/'
modelDirectory <- paste0( antsrnetDirectory, 'Models/' )
baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/'

source( paste0( modelDirectory, 'createUnetModel.R' ) )
source( paste0( modelDirectory, 'unetUtilities.R' ) )
source( paste0( baseDirectory, 'Scripts/unetBatchGenerator.R' ) )

classes <- c( "background", "defect", "hypo", "normal", "hyper" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Ventilation" )
channelSize <- length( imageMods )

dataDirectory <- paste0( baseDirectory, 'data/' )
trainingImageDirectory <- paste0( dataDirectory, 
  'Ventilation/Images_isotropic_train/' )
trainingImageFiles <- list.files( path = trainingImageDirectory, 
  pattern = "*Ventilation.nii.gz", full.names = TRUE )

trainingSegmentationFiles <- list()
trainingTransforms <- list()

for( i in 1:length( trainingImageFiles ) )
  {
  subjectId <- basename( trainingImageFiles[i] )
  subjectId <- sub( "Ventilation.nii.gz", '', subjectId )

  trainingSegmentationFiles[[i]] <- paste0( dataDirectory,
    'Ventilation/Segmentations_isotropic_train/', subjectId, 
    "Segmentation.nii.gz" )
  if( !file.exists( trainingSegmentationFiles[[i]] ) )
    {
    stop( paste( "Segmentation file", trainingSegmentationFiles[[i]], 
      "does not exist.\n" ) )
    }

  xfrmPrefix <- paste0( dataDirectory, 'Transforms/', subjectId, "Ventilation_" )

  fwdtransforms <- c()
  fwdtransforms[1] <- paste0( xfrmPrefix, '1Warp.nii.gz' )
  fwdtransforms[2] <- paste0( xfrmPrefix, '0GenericAffine.mat' )
  invtransforms <- c()
  invtransforms[1] <- paste0( xfrmPrefix, '0GenericAffine.mat' )
  invtransforms[2] <- paste0( xfrmPrefix, '1InverseWarp.nii.gz' )

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

paddedImageSize <- c( 128, 128, 128 )

unetModel <- createUnetModel3D( c( paddedImageSize, channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  layers = 1:3 )

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
validationIndices <- sampleIndices[( validationSplit + 1 ):numberOfTrainingData]

trainingData <- unetImageBatchGenerator$new( 
  imageList = trainingImageFiles[trainingIndices], 
  segmentationList = trainingSegmentationFiles[trainingIndices], 
  transformList = trainingTransforms[trainingIndices], 
  referenceImageList = trainingImageFiles, 
  referenceTransformList = trainingTransforms
  )

trainingDataGenerator <- trainingData$generate( batchSize = batchSize, 
  paddedSize = paddedImageSize )

validationData <- unetImageBatchGenerator$new( 
  imageList = trainingImageFiles[validationIndices], 
  segmentationList = trainingSegmentationFiles[validationIndices], 
  transformList = trainingTransforms[validationIndices],
  referenceImageList = trainingImageFiles, 
  referenceTransformList = trainingTransforms
  )

validationDataGenerator <- validationData$generate( batchSize = batchSize,
  paddedSize = paddedImageSize )

###
#
# Run training
#

track <- unetModel$fit_generator( 
  generator = reticulate::py_iterator( trainingDataGenerator ), 
  steps_per_epoch = ceiling( 400 / batchSize ),
  epochs = 40,
  validation_data = reticulate::py_iterator( validationDataGenerator ),
  validation_steps = ceiling( 100 / batchSize ),
  callbacks = list( 
    callback_model_checkpoint( paste0( baseDirectory, "unetModel.h5" ), 
      monitor = 'val_loss', save_best_only = TRUE, save_weights_only = FALSE,
      verbose = 1, mode = 'auto', period = 1 )
    # callback_early_stopping( monitor = 'val_loss', min_delta = 0.001, 
    #   patience = 10 ),
    # callback_reduce_lr_on_plateau( monitor = 'val_loss', factor = 0.5,
    #   patience = 0, epsilon = 0.001, cooldown = 0 )
                  # callback_early_stopping( patience = 2, monitor = 'loss' ),
    )
  )







