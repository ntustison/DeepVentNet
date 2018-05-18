library( ggplot2 )
library( reshape2 )

directory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/Manuscript/'

dice <- read.csv( paste0( directory, "diceProton.csv" ) )
dice <- dice[, c( 1, 5, 6, 7 )]
colnames( dice ) <- c( "ID", "Whole", "Right", "Left" )

diceLong <- melt( dice, id.vars = c( "ID" ), variable.name = "WhichLung", 
  value.name = "Dice" )

dicePlot <- ggplot( diceLong, aes( x = factor( WhichLung ), y = Dice, fill = factor( WhichLung ) ) ) +
  geom_jitter( position = position_jitter( width = 0.1, height = 0.01 ), aes( colour = factor( WhichLung ) ) ) +
  geom_boxplot( alpha = 0.5, show.legend = TRUE, outlier.shape = NA ) +
  xlab( "Lung" ) + ylab( "Dice" ) + 
  theme( legend.position = "none" )

ggsave( filename = paste0( directory, 'Figures/diceProton.pdf' ), 
  width = 5, height = 3, units = 'in' )  