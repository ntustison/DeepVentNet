library( ggplot2 )
library( reshape2 )

directory <- '/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/Manuscript/'

dice <- read.csv( paste0( directory, "ventilationStaple.csv" ) )

diceLong <- melt( dice, id.vars = c( "ID", "Rater" ), variable.name = "Region", 
  value.name = "Dice" )

levels( diceLong$Rater ) <- c( "Reader 1", "Reader 2", "Reader 3", "Atropos", "U-net" )
levels( diceLong$Region ) <- c( "Total", "Normal lung", "Ventilation defect" )

dicePlot <- ggplot( diceLong, aes( x = Rater, y = Dice, fill = Rater ) ) +
  facet_grid( .~Region ) +
  geom_jitter( position = position_jitter( width = 0.1, height = 0.0 ), 
    aes( colour = Rater ), size = 0.5 ) +
  geom_boxplot( alpha = 0.5, show.legend = FALSE, outlier.shape = NA ) +
  xlab( "" ) + ylab( "Dice" ) +
  theme( axis.text.x = element_text( angle = 45, hjust = 1, size = 8 ) ) +
  theme( legend.position = "none" ) +
  scale_x_discrete( limits = levels( diceLong$Rater ) )

ggsave( filename = paste0( directory, 'Figures/ventilationStaple.pdf' ), 
  width = 7, height = 3, units = 'in' )    


for( rater in levels( factor( dice$Rater ) ) )  
  {
  cat( rater, "\n" )  
  rMean <- mean( dice$Total[which( dice$Rater == rater )])
  rSd <- sd( dice$Total[which( dice$Rater == rater )])
  cat( "Total:  ", rMean, ", ", rSd, "\n" )

  rMean <- mean( dice$Normal.Lung[which( dice$Rater == rater )])
  rSd <- sd( dice$Normal.Lung[which( dice$Rater == rater )])
  cat( "Normal.Lung:  ", rMean, ", ", rSd, "\n" )

  rMean <- mean( dice$Ventilation.Defect[which( dice$Rater == rater )])
  rSd <- sd( dice$Ventilation.Defect[which( dice$Rater == rater )])
  cat( "Total:  ", rMean, ", ", rSd, "\n" )
  }