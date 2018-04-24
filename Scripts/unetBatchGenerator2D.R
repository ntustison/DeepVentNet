#' @export

unetImageBatchGenerator2D <- R6::R6Class( "UnetImageBatchGenerator2D",

  public = list( 
    
    imageList = NULL,

    segmentationList = NULL,

    transformList = NULL,

    referenceImageList = NULL,

    referenceTransformList = NULL,

    pairwiseIndices = NULL,

    initialize = function( imageList = NULL, segmentationList = NULL, 
      transformList = NULL, referenceImageList = NULL, 
      referenceTransformList = NULL )
      {
        
      if( !usePkg( "ANTsR" ) )
        {
        stop( "Please install the ANTsR package." )
        }
      if( !usePkg( "abind" ) )
        {
        stop( "Please install the abind package." )
        }

      if( !is.null( imageList ) )
        {
        self$imageList <- imageList
        } else {
        stop( "Input images must be specified." )
        }

      if( !is.null( segmentationList ) )
        {
        self$segmentationList <- segmentationList
        } else {
        stop( "Input segmentation images must be specified." )
        }

      if( !is.null( transformList ) )
        {
        self$transformList <- transformList
        } else {
        stop( "Input transforms must be specified." )
        }

      if( is.null( referenceImageList ) || 
        is.null( referenceTransformList ) )
        {
        self$referenceImageList <- imageList
        self$referenceTransformList <- transformList
        } else {
        self$referenceImageList <- referenceImageList
        self$referenceTransformList <- referenceTransformList
        }

      self$pairwiseIndices <- expand.grid( source = 1:length( self$imageList ), 
        reference = 1:length( self$referenceImageList ) )  

      },

    generate = function( batchSize = 32L, paddedSize = NULL, 
      direction = 2, sliceSamplingRate = 0.2 )    
      {
      # shuffle the source data
      sampleIndices <- sample( length( self$imageList ) )
      self$imageList <- self$imageList[sampleIndices]
      self$segmentationList <- self$segmentationList[sampleIndices]
      self$transformList <- self$transformList[sampleIndices]

      # shuffle the reference data
      sampleIndices <- sample( length( self$referenceImageList ) )
      self$referenceImageList <- self$referenceImageList[sampleIndices]
      self$referenceTransformList <- self$referenceTransformList[sampleIndices]

      currentPassCount <- 1L

      function() 
        {
        # Shuffle the data after each complete pass 

        if( currentPassCount >= nrow( self$pairwiseIndices ) )
          {
          # shuffle the source data
          sampleIndices <- sample( length( self$imageList ) )
          self$imageList <- self$imageList[sampleIndices]
          self$segmentationList <- self$segmentationList[sampleIndices]
          self$transformList <- self$transformList[sampleIndices]

          # shuffle the reference data
          sampleIndices <- sample( length( self$referenceImageList ) )
          self$referenceImageList <- self$referenceImageList[sampleIndices]
          self$referenceTransformList <- self$referenceTransformList[sampleIndices]

          currentPassCount <- 1L
          }

        rowIndices <- currentPassCount + 0:( batchSize - 1L )

        outOfBoundsIndices <- which( rowIndices > nrow( self$pairwiseIndices ) )
        while( length( outOfBoundsIndices ) > 0 )
          {
          rowIndices[outOfBoundsIndices] <- rowIndices[outOfBoundsIndices] - 
            nrow( self$pairwiseIndices )
          outOfBoundsIndices <- which( rowIndices > nrow( self$pairwiseIndices ) )
          }
        batchIndices <- self$pairwiseIndices[rowIndices,]

        batchImages <- self$imageList[batchIndices$source]
        batchSegmentations <- self$segmentationList[batchIndices$source]
        batchTransforms <- self$transformList[batchIndices$source]

        batchReferenceImages <- self$referenceImageList[batchIndices$reference]
        batchReferenceTransforms <- self$referenceTransformList[batchIndices$reference]

        channelSize <- length( batchImages[[1]] )

        if( !is.null( paddedSize ) )
          {
          imageSize2D <- paddedSize  
          }
        batchX <- array( data = 0, dim = c( batchSize, imageSize2D, channelSize ) )
        batchY <- array( data = 0, dim = c( batchSize, imageSize2D ) )

        currentPassCount <<- currentPassCount + batchSize

        i <- 1
        while( i <= batchSize )
          {
          subjectBatchImages <- batchImages[[i]]  

          referenceX <- antsImageRead( batchReferenceImages[[i]][1], dimension = 3 )
          referenceXfrm <- batchReferenceTransforms[[i]]
          imageSize <- dim( referenceX )

          sourceXfrm <- batchTransforms[[i]]

          boolInvert <- c( TRUE, FALSE, FALSE, FALSE )
          transforms <- c( referenceXfrm$invtransforms[1], 
            referenceXfrm$invtransforms[2], sourceXfrm$fwdtransforms[1],
            sourceXfrm$fwdtransforms[2] )

          numberOfSlices <- imageSize[direction]
          numberOfExtractedSlices <- round( sliceSamplingRate * numberOfSlices )
          slicesToExtract <- sample.int( n = imageSize[direction], 
            size = numberOfExtractedSlices )

          sourceY <- antsImageRead( batchSegmentations[[i]], dimension = 3 )

          warpedImageY <- antsApplyTransforms( referenceX, sourceY, 
            interpolator = "nearestNeighbor", transformlist = transforms,
            whichtoinvert = boolInvert  )

          warpedImagesX <- list()
          for( j in seq_len( channelSize ) )
            {  
            sourceX <- antsImageRead( subjectBatchImages[j], dimension = 3 )

            warpedImagesX[[j]] <- antsApplyTransforms( referenceX, sourceX, 
              interpolator = "linear", transformlist = transforms,
              whichtoinvert = boolInvert )          
            }

          for( k in seq_len( numberOfExtractedSlices ) )
            {
            sliceWarpedImageY <- 
              extractSlice( warpedImageY, slicesToExtract[k], direction )
            sliceWarpedArrayY <- as.array( sliceWarpedImageY )

            paddingSize2D <- imageSize2D - imageSize[-direction]
            for( d in 1:length( paddingSize2D ) )
              {
              if( paddingSize2D[d] > 0 )  
                {
                paddingSizeDim <- dim( sliceWarpedArrayY )
                paddingSizeDim[d] <- paddingSize2D[d]  
                zerosArray <- array( 0, dim = c( paddingSizeDim ) )  
                sliceWarpedArrayY <- abind( sliceWarpedArrayY, zerosArray, 
                  along = d )
                }
              }

            # antsImageWrite( as.antsImage( sliceWarpedArrayY ), "~/Desktop/arrayY.nii.gz" )
            batchY[i,,] <- sliceWarpedArrayY

            for( j in seq_len( channelSize ) )
              {  
              sliceWarpedArrayX <- as.array( extractSlice( warpedImagesX[[j]], 
                slicesToExtract[k], direction ) )

              sliceWarpedArrayX <- ( sliceWarpedArrayX - min( sliceWarpedArrayX ) ) / 
                ( max( sliceWarpedArrayX ) - min( sliceWarpedArrayX ) )

              paddingSize2D <- imageSize2D - imageSize[-direction]
              for( d in 1:length( paddingSize2D ) )
                {
                if( paddingSize2D[d] > 0 )  
                  {
                  paddingSizeDim <- dim( sliceWarpedArrayX )
                  paddingSizeDim[d] <- paddingSize2D[d]  
                  zerosArray <- array( 0, dim = c( paddingSizeDim ) )  
                  sliceWarpedArrayX <- abind( sliceWarpedArrayX, zerosArray, 
                    along = d )
                  }
                }

              # antsImageWrite( as.antsImage( sliceWarpedArrayX ), "~/Desktop/arrayX.nii.gz" )
              # readline( prompt = "Press [enter] to continue\n" )
              batchX[i,,,j] <- sliceWarpedArrayX
              }

            i <- i + 1
            if( i > batchSize )
              {
              break  
              }
            }
          }
  
        segmentationLabels <- sort( unique( as.vector( batchY ) ) )

        encodedBatchY <- encodeY( batchY, segmentationLabels )  

        return( list( batchX, encodedBatchY ) )        
        }   
      }
    )
  )