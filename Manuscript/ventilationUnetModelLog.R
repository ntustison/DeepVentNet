library( ggplot2 )
library( reshape2 )

directory <- '/Users/ntustison/Documents/Academic/InProgress/DeepVentNet/Manuscript/'

logUnet <- read.csv( paste0( directory, "ventilationUnetModelLog.csv" ) )
logUnetLong <- melt( logUnet, id.vars = c( "Epoch" ), variable.name = "Data", 
  value.name = "Dice" )

unetModelAccuracyPlot <- 
  ggplot( data = logUnetLong, aes( x = Epoch, y = Dice, colour = Data ) ) +
  geom_point( shape = 1, size = 1.0 ) +
  geom_line( size = 0.75 ) +
  ggtitle( "Ventilation U-net model training" )

ggsave( paste0( directory, "Figures/unetModelVentilationAccuracyPlot.pdf" ), 
  plot = unetModelAccuracyPlot, width = 8, height = 3.5, units = 'in' )





