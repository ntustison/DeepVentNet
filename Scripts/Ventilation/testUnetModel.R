library( ANTsR )
library( keras )

keras::backend()$clear_session()

antsrnetDirectory <- '/Users/ntustison/Pkg/ANTsRNet/'
modelDirectory <- paste0( antsrnetDirectory, 'Models/' )
baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepLearning/'

source( paste0( modelDirectory, 'createUnetModel.R' ) )
source( paste0( modelDirectory, 'unetUtilities.R' ) )

classes <- c( "background", "defect", "hypo", "normal1", "normal2" )
numberOfClassificationLabels <- length( classes )

imageMods <- c( "Ventilation" )
channelSize <- length( imageMods )

dataDirectory <- paste0( baseDirectory, 'data/' )
trainingDirectory <- paste0( dataDirectory, 
  'Ventilation/Images_isotropic_train/' )
ventilationImages <- list.files( path = trainingDirectory, 
  pattern = "*Ventilation.nii.gz", full.names = TRUE )

###
#
# Create the Unet model
#

direction <- 3

ssdOutput <- createUnetModel2D( 
  c( inputImageSize[-direction] + paddingSize[-direction], channelSize ), 
  numberOfClassificationLabels = numberOfClassificationLabels, 
  minScale = 0.05, maxScale = 0.5,
  aspectRatiosPerLayer = 
    list( c( '1:1', '1.5:1', '1:1.5' ),
          c( '1:1', '1.5:1', '1:1.5' ),
          c( '1:1', '1.5:1', '1:1.5' ),
          c( '1:1', '1.5:1', '1:1.5' )
        ),
  variances = rep( 1.0, 4 ) )

ssdModel <- ssdOutput$ssdModel 
anchorBoxes <- ssdOutput$anchorBoxes

load_model_weights_hdf5( ssdModel, 
  filepath = paste0( baseDirectory, 'ssd7Weights.h5' ) )

optimizerAdam <- optimizer_adam( 
  lr = 0.001, beta_1 = 0.9, beta_2 = 0.999, epsilon = 1e-08, decay = 5e-05 )

ssdLoss <- lossSsd$new( backgroundRatio = 3L, minNumberOfBackgroundBoxes = 0L, 
  alpha = 1.0, numberOfClassificationLabels = numberOfClassificationLabels )

ssdModel %>% compile( loss = ssdLoss$compute_loss, optimizer = optimizerAdam )

batchSize <- length( testingImageFiles )

for( i in 1:length( testingImageFiles ) )
  {
  cat( "Reading", dirname( testingImageFiles[[i]][1] ), "\n" )  

  X_test <- array( data = 0, dim = c( inputImageSize[direction], 
    paddingSize[-direction] + inputImageSize[-direction], channelSize ) )

  for( j in 1:channelSize )
    {
    image <- antsImageRead( testingImageFiles[[i]][j], dimension = 3 )

    for( k in 1:dim( image )[direction] )
      {
      imageSlice <- as.array( extractSlice( image, k, direction ) )

      paddingSize2D <- paddingSize[-direction]
      for( d in 1:length( paddingSize2D ) )
        {
        if( paddingSize2D[d] > 0 )  
          {
          paddingSizeDim <- dim( imageSlice )
          paddingSizeDim[d] <- paddingSize2D[d]  
          zerosArray <- array( 0, dim = c( paddingSizeDim ) )  
          imageSlice <- abind( imageSlice, zerosArray, along = d )
          }  
        }
      }
    X_test[k,,,j] <- imageSlice  
    }

  predictedData <- ssdModel %>% predict( X_test, verbose = 1 )
  predictedDataDecoded <- decodeY2D( predictedData, 
    inputImageSize[-direction] + paddingSize[-direction], 
    confidenceThreshold = 0.4, overlapThreshold = 0.4 )

  imageArray <- array( 0, dim = dim( image ) )
  for( j in 1:length( predictedDataDecoded ) )  
    {
    sliceBoxes <- predictedDataDecoded[[j]]
    for( k in seq_len( nrow( sliceBoxes ) ) )
      {
      classId <- sliceBoxes[k, 1]  
      xmin <- sliceBoxes[k, 3]  
      xmax <- sliceBoxes[k, 4]  
      ymin <- sliceBoxes[k, 5]  
      ymax <- sliceBoxes[k, 6]  

      if( direction == 1 )
        {
        imageArray[j, xmin:xmax, ymin:ymax] <- classId
        } else if( direction == 2 ) {
        imageArray[xmin:xmax, j, ymin:ymax] <- classId
        } else {
        imageArray[xmin:xmax, ymin:ymax, j] <- classId
        }
      }
    }

  boundingBoxFile <- paste0( dirname( testingImageFiles[[i]][1] ), "/BoundingBox.nii.gz" ) 

  cat( "Writing", boundingBoxFile, "\n" )
  antsImageWrite( as.antsImage( imageArray, reference = image ), boundingBoxFile )  
  }



