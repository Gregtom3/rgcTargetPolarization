#!/bin/bash
USERNAME="$USER"


#################################################################################
# EDIT HERE
#################################################################################
#
#
# Path to this repository
pathtorepo=/work/clas12/users/$USERNAME/rgcTargetPolarization
#
# Location for output log files, shell scripts, etc.
farmoutdir=/farm_out/$USERNAME/clas12analysis.sidis.data/rgc/tpol
#
#
#
#################################################################################
# EDIT HERE
#################################################################################


hl="---------------------------------------------------------------"
if [ $# -lt 1 ]; then
  echo """
  USAGE: $0 [version] [flags(optional)]
  Automates the sending of slurm analysis jobs for RGC 
  Each job executes the ProcessInclusive.C macro in the previous directory
   - [version]: [8.3.2 or 8.3.4 or 8.4.0 or 8c.4.0 or 8.5.0_HBT or 8.7.0_TBT or 10.0.2_TBT_11_27_2023 or 10.0.2_TBT_12_06_2023 or pass1] 
   - [flags]:
              -a      (append to existing data directory (./data/<version>/)
              -o      (overwrite existing data directory (./data/<version>/))
  """
  exit 2
fi

VERSIONS="8.3.2 8.3.4 8.4.0 8c.4.0 8.5.0_HBT 8.7.0_TBT 10.0.2_TBT_11_27_2023 10.0.2_TBT_12_06_2023 10.0.4_01_10_24_dst_denoise_6302 pass1"
nCPUs=1
memPerCPU=1000

declare -A flags
declare -A booleans
args=()

while [ "$1" ];
do
    arg=$1
    if [ "${1:0:1}" == "-" ]
    then
      shift
      rev=$(echo "$arg" | rev)
      if [ -z "$1" ] || [ "${1:0:1}" == "-" ] || [ "${rev:0:1}" == ":" ]
      then
        bool=$(echo ${arg:1} | sed s/://g)
        booleans[$bool]=true
      else
        value=$1
        flags[${arg:1}]=$value
        shift
      fi
    else
      args+=("$arg")
      shift
    fi
done
#################################################################################
# Create log and slurm dir for execution
logdir=""
slurmdir=""
NOW=$( date '+%F_%H_%M' )
NOWdir=$farmoutdir/$NOW
if [ -d "${NOWdir}/" ]; then
    rm -r ${NOWdir}
fi
mkdir -p ${NOWdir}
logdir=$NOWdir"/log"
slurmdir=$NOWdir"/slurm"
if [ -d "${logdir}/" ]; then
    rm -r ${logdir}
fi
if [ -d "${slurmdir}/" ]; then
    rm -r ${slurmdir}
fi
mkdir ${logdir}
mkdir ${slurmdir}
#################################################################################

version=${args[0]}

if ! echo "$VERSIONS" | grep -q "$version"; then
    echo $hl
    echo "ERROR: Version $version not valid. Must use from following list [$VERSIONS]"
    exit 2
fi

# Location for output ROOT TTrees, TFiles
datadir=/volatile/clas12/users/$USERNAME/clas12analysis.sidis.data/rgc/tpol/data/$version

##################################################################################################
PWD=$pwd

existing_runs=()
if [ ! -z ${booleans["o"]} ] && [ ! -z ${booleans["a"]} ]; then
    echo $hl
    echo "You cannot use the -o (overwrite) and -a (append) flag simultaneously...Aborting..."
    exit 2
elif [ ! -z ${booleans["o"]} ]; then
    echo $hl
    echo "Are you sure you would like to overwrite $datadir (Y/N):"
    read overwrite
    if [ $overwrite == "Y" ]; then
	echo $hl
	echo "Overwriting $datadir ..."
	rm -r $datadir
	echo "Overwritten!"
	mkdir -p $datadir
    elif [ $overwrite == "N" ]; then
	echo $hl
	echo "Overwrite cancelled...Aborting..."
	exit 2
    else
	echo $hl
	echo "ERROR: Please answer Y or N...Aborting..."
	exit 2
    fi
elif [ ! -z ${booleans["a"]} ]; then
    echo $hl
    echo "Are you sure you would like to append to $datadir (Y/N):"
    read append
    if [ $append == "Y" ]; then
	echo $hl
	echo "Appending to $datadir ..."
	for dir in  $datadir/HBT $datadir/TBT; do
	    for file in $dir/*.root; do
		# Extract the numbers from the filename
		num=$(echo $file | grep -o '[0-9]\+')
		# Add the number to the list
		existing_runs+=("$num")
	    done
	done
	echo "Existing runs are ${existing_run[@]}"
    elif [ $append == "N" ]; then
	echo $hl
	echo "Appending cancelled...Aborting..."
	exit 2
    else
	echo $hl
	echo "ERROR: Please answer Y or N...Aborting..."
	exit 2
    fi
else
    echo $hl
    echo "ERROR: Directory $datadir already exists. You must specify a new [dir] or use -o to overwrite OR -a to append...Aborting..."
    exit 2
fi    


##############################################################################################################
echo "Pulling files from version $version"
if [[ $version == "10.0.4_01_10_24_dst_denoise_6302" ]]; then
    trainhipodir=("/volatile/clas12/rg-c/production/calib/$version/dst/train/sidisdvcs/*.hipo")
    reconhipodir=("/volatile/clas12/rg-c/production/calib/$version/dst/recon/*.hipo")
elif [[ $version == "8.7.0_TBT" ]] || [[ $version == *"10.0.2_TBT"* ]]; then
    trainhipodir=("/volatile/clas12/rg-c/production/dst/$version/dst/train/sidisdvcs/*.hipo")
    reconhipodir=("/volatile/clas12/rg-c/production/dst/$version/dst/recon/*.hipo")
elif [[ $version == "pass1" ]]; then
    trainhipodir=("/cache/clas12/rg-c/production/summer22/pass1/10.5gev/NH3/dst/train/sidisdvcs/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/ND3/dst/train/sidisdvcs/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/C/dst/train/sidisdvcs/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/CH2/dst/train/sidisdvcs/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/ET/dst/train/sidisdvcs/*.hipo")
    reconhipodir=("/cache/clas12/rg-c/production/summer22/pass1/10.5gev/NH3/dst/recon/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/ND3/dst/recon/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/C/dst/recon/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/CH2/dst/recon/*.hipo" "/cache/clas12/rg-c/production/summer22/pass1/10.5gev/ET/dst/recon/*.hipo")
else
    trainhipodir=("/volatile/clas12/rg-c/production/ana_data/*/$version/dst/train/sidisdvcs/*.hipo")
    reconhipodir=("/volatile/clas12/rg-c/production/ana_data/*/$version/dst/recon/*.hipo")
fi

# Count files in all directories specified in the trainhipodir array
file_count=0
for dir in "${trainhipodir[@]}"; do
    file_count=$((file_count + $(ls -1 $dir | wc -l)))
done

##############################################################################################################
echo $hl
echo "Reading RCDB quantities (4 total)"
echo $hl

declare -a targets
declare -a hwps
declare -a tpols
declare -a beamEs

# Initialize strings to accumulate results
all_targets=""
all_hwps=""
all_tpols=""
all_beamEs=""

# Loop through each directory in trainhipodir
for dir in "${trainhipodir[@]}"; do
    echo "Reading in target types from $dir"
    new_targets=$(python readRCDB.py $dir "target")
    targets+=($new_targets)
    all_targets+="$new_targets "
    echo "Reading in HWP status from $dir"
    new_hwps=$(python readRCDB.py $dir "half_wave_plate")
    hwps+=($new_hwps)
    all_hwps+="$new_hwps "

    echo "Reading in RCDB Tpol from $dir"
    new_tpols=$(python readRCDB.py $dir "target_polarization")
    tpols+=($new_tpols)
    all_tpols+="$new_tpols "

    echo "Reading in Beam Energies from $dir"
    new_beamEs=$(python readRCDB.py $dir "beam_energy")
    beamEs+=($new_beamEs)
    all_beamEs+="$new_beamEs "
done

echo "Done reading RCDB"
echo $hl

echo "Targets: $all_targets"
echo "HWP statuses: $all_hwps"
echo "Target polarizations: $all_tpols"
echo "Beam Energies: $all_beamEs"


##############################################################################################################

# Loop to handle each directory separately
i=0
for dir in "${trainhipodir[@]}"; do
    files=( $(ls $dir) )
    for hipo in "${files[@]}"; do
        # Extract the corresponding metadata using the current value of i
        targ=$(echo ${targets[$i]} | tr -d "[',\[\]]")
        hwp=$(echo ${hwps[$i]} | tr -d "[',\[\]]")
        tpol=$(echo ${tpols[$i]} | tr -d "[',\[\]]")
        beamE=$(echo ${beamEs[$i]} | tr -d "[',\[\]]")
        ((i++))

        cookType=""
        if [[ $hipo == *"/TBT/"* ]]; then
            cookType="TBT"
        elif [[ $hipo == *"/pass1/"* ]]; then
            cookType="pass1"
        else
            cookType="HBT"
        fi

        base=$(basename "${hipo}")
        run=$(echo $base | grep -o '[0-9]\+' | sed 's/^0*//')
        if [ ! -z ${booleans["a"]} ]; then  
            if echo $existing_runs | grep -w -q "$run"; then
                echo "Skipping run $run since it already exists in this to-be-appended directory ($datadir)"
                continue
            fi
        fi

        slurmshell=${slurmdir}"/sidisdvcs_${run}.sh"
        slurmslurm=${slurmdir}"/sidisdvcs_${run}.slurm"

        touch $slurmshell
        touch $slurmslurm
        chmod +x $slurmshell

        cat >> $slurmslurm <<EOF
#!/bin/bash
#SBATCH --account=clas12
#SBATCH --partition=scavenger_gpu
#SBATCH --mem-per-cpu=${memPerCPU}
#SBATCH --job-name=job_sidisdvcs_${run}
#SBATCH --cpus-per-task=${nCPUs}
#SBATCH --time=24:00:00
#SBATCH --output=${logdir}/sidisdvcs_${run}.out
#SBATCH --error=${logdir}/sidisdvcs_${run}.err
$slurmshell
EOF

        cat >> $slurmshell << EOF
#!/bin/tcsh
source /group/clas12/packages/setup.csh
module load clas12/pro
cd $pathtorepo/
clas12root -b -q ${pathtorepo}/ProcessInclusive.C\(\"$hipo\",\"$datadir\",$run,$beamE,$hwp,$tpol,\"$targ\",\"$cookType\"\)
echo "Done"
EOF

        sbatch $slurmslurm
    done
done













##############################################################################################################
# echo "Pulling files from version $version"
# if [[ $version == "10.0.4_01_10_24_dst_denoise_6302" ]]; then
#     trainhipodir="/volatile/clas12/rg-c/production/calib/$version/dst/train/sidisdvcs/*.hipo"
#     reconhipodir="/volatile/clas12/rg-c/production/calib/$version/dst/recon/*.hipo"
# elif [[ $version == "8.7.0_TBT" ]] || [[ $version == *"10.0.2_TBT"* ]]; then
#     trainhipodir="/volatile/clas12/rg-c/production/dst/$version/dst/train/sidisdvcs/*.hipo"
#     reconhipodir="/volatile/clas12/rg-c/production/dst/$version/dst/recon/*.hipo"
# elif [[ $version == "pass1" ]]; then
#     trainhipodir="/cache/clas12/rg-c/production/summer22/pass1/10.5gev/{NH3,ND3}/dst/train/sidisdvcs/*.hipo"
#     reconhipodir="/cache/clas12/rg-c/production/summer22/pass1/10.5gev/{NH3,ND3}/dst/recon/*.hipo"
# else
#     trainhipodir="/volatile/clas12/rg-c/production/ana_data/*/$version/dst/train/sidisdvcs/*.hipo"
#     reconhipodir="/volatile/clas12/rg-c/production/ana_data/*/$version/dst/recon/*.hipo"
# fi
# file_count=$(ls -1 $trainhipodir | wc -l)
# ##############################################################################################################
# echo $hl
# echo "Reading RCDB quantities (4 total)"
# echo $hl
# echo "Reading in target types"
# targets=$(python readRCDB.py $trainhipodir "target")
# echo "Reading in HWP status"
# hwps=$(python readRCDB.py $trainhipodir "half_wave_plate")
# echo "Reading in RCDB Tpol"
# tpols=$(python readRCDB.py $trainhipodir "target_polarization")
# echo "Reading in Beam Energies"
# beamEs=$(python readRCDB.py $trainhipodir "beam_energy")
# echo "Done reading RCDB"
# echo $hl

# echo $targets $hwps $tpols $beamEs



# for ((i=0;i<$file_count;i++)); do

#     hipo=`echo $trainhipodir | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
#     targ=`echo $targets | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
#     hwp=`echo $hwps | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
#     tpol=`echo $tpols | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
#     beamE=`echo $beamEs | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`

#     cookType=""
#     if [[ $hipo == *"/TBT/"* ]]; then
# 	cookType="TBT"
#     else
# 	cookType="HBT"
#     fi

#     base=$(basename "${hipo}")
#     run=$(echo $base | grep -o '[0-9]\+' | sed 's/^0*//')
#     if [ ! -z ${booleans["a"]} ]; then  
# 	if echo $existing_runs | grep -w -q "$run"; then
# 	    echo "Skipping run $run since it already exists in this to-be-appended directory ($datadir)"
# 	    continue
# 	fi
#     fi

    
#     slurmshell=${slurmdir}"/sidisdvcs_${run}.sh"
#     slurmslurm=${slurmdir}"/sidisdvcs_${run}.slurm"

#     touch $slurmshell
#     touch $slurmslurm
#     chmod +x $slurmshell

#     cat >> $slurmslurm <<EOF
# #!/bin/bash
# #SBATCH --account=clas12
# #SBATCH --partition=production
# #SBATCH --mem-per-cpu=${memPerCPU}
# #SBATCH --job-name=job_sidisdvcs_${run}
# #SBATCH --cpus-per-task=${nCPUs}
# #SBATCH --time=24:00:00
# #SBATCH --output=${logdir}/sidisdvcs_${run}.out
# #SBATCH --error=${logdir}/sidisdvcs_${run}.err
# $slurmshell
# EOF

#     cat >> $slurmshell << EOF
# #!/bin/tcsh
# source /group/clas12/packages/setup.csh
# module load clas12/pro
# cd $pathtorepo/
# clas12root -b -q ${pathtorepo}/ProcessInclusive.C\(\"$hipo\",\"$datadir\",$run,$beamE,$hwp,$tpol,\"$targ\",\"$cookType\"\)
# echo "Done"
# EOF

# #    sbatch $slurmslurm
    
# done
