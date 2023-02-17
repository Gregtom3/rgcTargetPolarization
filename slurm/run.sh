#!/bin/bash
#VERSION="8.5.0_HBT"
#sidisdvcs="/volatile/clas12/rg-c/production/dst/${VERSION}/dst/train/sidisdvcs/*"
VERSION="8.4.0"
sidisdvcs="/volatile/clas12/rg-c/production/ana_data/TBT/$VERSION/dst/train/sidisdvcs/*"
tmp_prefix=/work/clas12/users/gmat/tmp/rgc-scaler-run
destination=/volatile/clas12/users/gmat/clas12analysis.sidis.data/rgc-scaler${VERSION}

for hipo in $sidisdvcs
do
    echo $(basename $hipo) | sed -e s/[^0-9]//g | while read -r line; 
do 	
    run="${line##0}"
    dir=/volatile/clas12/users/gmat/clas12analysis.sidis.data/rgc-scaler${VERSION}/
    if ls $dir| sed -e s/[^0-9]//g| grep -w -q $run
    then
	echo "Skipping run ${run}"
    else
	echo "Scanning scalers for ${run} ${VERSION}"
	cook="${VERSION}"
	sbatch /work/clas12/users/gmat/rgcTargetPolarization/slurm/scanSlurm.slurm ${run} ${tmp_prefix} ${destination} ${cook}
    fi
done    
done


