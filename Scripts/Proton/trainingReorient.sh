#! /usr/sh

baseDirectory=/Users/ntustison/Data/HeliumLungStudies/DeepVentNet/
template=${baseDirectory}/Data/Proton/Training/Template/T_template0.nii.gz

for i in `ls ${baseDirectory}/Data/Proton/Training/Images/*Proton.nii.gz`;
  do
    id=`basename ${i/Proton\.nii\.gz}`
    antsRegistration -d 3 -v 1 \
      -o ${baseDirectory}/Data/Proton/Training/TemplateReorient/TR_${id} \
      -r [$template,$i,0] \
      -t Translation[0.1] \
      -m MI[$template,$i,1,32] \
      -c 0 -s 0 -f 1
  done