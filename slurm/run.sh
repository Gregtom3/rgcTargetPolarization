#!/bin/bash
VERSION="pass1"
# Define sidisdvcs as an array of directory paths
sidisdvcs=(
    "/cache/clas12/rg-c/production/summer22/$VERSION/10.5gev/NH3/dst/train/sidisdvcs/*"
    "/cache/clas12/rg-c/production/summer22/$VERSION/10.5gev/ND3/dst/train/sidisdvcs/*"
    "/cache/clas12/rg-c/production/summer22/$VERSION/10.5gev/C/dst/train/sidisdvcs/*"
)
tmp_prefix=/work/clas12/users/gmat/tmp/rgc-scaler-run
destination=/volatile/clas12/users/gmat/clas12analysis.sidis.data/rgc-scaler${VERSION}
rm -r $destination
mkdir -p $destination

# Iterate over each directory path in the array
for dirpath in "${sidisdvcs[@]}"
do
    for hipo in $dirpath
    do
        echo $(basename $hipo) | sed -e s/[^0-9]//g | while read -r line; 
        do 
            run="${line##0}"
            dir=/volatile/clas12/users/gmat/clas12analysis.sidis.data/rgc-scaler${VERSION}/
            echo "Scanning scalers for ${run} ${VERSION}"
            cook="${VERSION}"
            header=$(echo "$hipo" | awk -F'/train/' '{print $1 "/"}')
            sbatch /work/clas12/users/gmat/rgcTargetPolarization/slurm/scanSlurm.slurm ${run} ${tmp_prefix} ${destination} ${header}
        done    
    done
done
