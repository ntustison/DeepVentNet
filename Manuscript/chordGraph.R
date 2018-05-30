library( circlize )

t <- read.csv( "~/Desktop/files.csv", colClasses = c( 'character', 'character' ) )
t$Source <- as.factor( substr( as.character( t$Source ), 0, 4 ) )
t$Reference <- as.factor( substr( as.character( t$Reference ), 0, 4 ) )

circlizeDataFrame <- data.frame( ReferenceLevel = factor(), SourceLevel = factor(),
  NumberOfConnections = integer() )

for( i in levels( t$Reference ) )
  { 
  for( j in levels( t$Source ) )
    {
    count <- length( which( t$Reference == i & t$Source == j ) )    
    circlizeDataFrame <- rbind( circlizeDataFrame, 
      data.frame( ReferenceLevel = i, SourceLevel = j, NumberOfConnections = count ) )
 
    }
  }

pdf( "~/Desktop/broken.pdf" )
grid.col <- setNames( rainbow( nlevels( t$Source ) ), levels( t$Source ) )
chordDiagram( circlizeDataFrame, annotationTrack = "grid", preAllocateTracks = 1, grid.col = grid.col )
circos.trackPlotRegion( track.index = 1, panel.fun = function(x, y) {
  xlim = get.cell.meta.data("xlim")
  ylim = get.cell.meta.data("ylim")
  sector.name = get.cell.meta.data("sector.index")
  circos.text(mean(xlim), ylim[1] + .1, sector.name, facing = "clockwise", niceFacing = TRUE, adj = c(0, 0.5))
  circos.axis(h = "top", labels.cex = 0.5, major.tick.percentage = 0.2, sector.index = sector.name, track.index = 2)
}, bg.border = NA)
circos.clear()
dev.off()

