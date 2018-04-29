library( ANTsR )
library( ANTsRNet )
library( keras )

keras::backend()$clear_session()

baseDirectory <- '/Users/ntustison/Data/HeliumLungStudies/DeepLearning/'

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

