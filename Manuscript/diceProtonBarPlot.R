library( ggplot2 )
library( reshape2 )

# directory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/Manuscript/'
directory <- '/Users/ntustison/Documents/Academic/InProgress/DeepVentNet/Manuscript/'

diceUnet <- read.csv( paste0( directory, "diceProton.csv" ) )
diceUnet <- diceUnet[, c( 1, 5, 6, 7 )]
colnames( diceUnet ) <- c( "ID", "Both", "Right", "Left" )
diceUnet$Pipeline <- 'UNet'

diceJlf <- read.csv( paste0( directory, "diceProtonJlf.csv" ) )
diceJlf <- diceJlf[, c( 1, 5, 6, 7 )]
colnames( diceJlf ) <- c( "ID", "Both", "Right", "Left" )
diceJlf$Pipeline <- 'JLF'

dice <- rbind( diceUnet, diceJlf )

diceLong <- melt( dice, id.vars = c( "ID", "Pipeline" ), variable.name = "WhichLung", 
  value.name = "Dice" )

dicePlot <- ggplot( diceLong, aes( x = factor( WhichLung ), y = Dice, 
    fill = factor( WhichLung ) ) ) +
  facet_grid( .~Pipeline ) +
  geom_jitter( position = position_jitter( width = 0.1, height = 0.0 ), aes( colour = factor( WhichLung ) ), size = 0.5 ) +
  geom_boxplot( alpha = 0.5, show.legend = TRUE, outlier.shape = NA ) +
  xlab( "Lung" ) + ylab( "Dice" ) + ylim( c( 0.7, 1.0 ) ) +
  theme( legend.position = "none" )

ggsave( filename = paste0( directory, 'Figures/diceProton.pdf' ), 
  width = 7, height = 3, units = 'in' )  