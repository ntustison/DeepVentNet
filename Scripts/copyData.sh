# /usr/bin/sh

baseDir=/Users/ntustison/Data/HeliumLungStudies/

# Copy ventilation images
imagesDir=${baseDir}/DeepLearning/Ventilation/Images/
segDir=${baseDir}/DeepLearning/Ventilation/Segmentations/

count=1311
for i in `find $baseDir -name "*Segmentation0N4.nii.gz"`; 
  do

    if [[ $i = *"Vertex"* ]];
      then
        echo "***** Don't copy $i"
        continue
      fi 
    j=${i/0N4/}; 
    
    if [[ -f $j ]]; 
      then 
        echo $i; 
        
        index=$(printf %06d $count)                  

        image=${imagesDir}/${index}Ventilation.nii.gz
        seg=${segDir}/${index}Segmentation.nii.gz
        cp $i ${image}
        cp $j ${seg}
        
        ((count++))
      fi  
    done
