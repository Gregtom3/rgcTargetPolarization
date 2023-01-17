#!/bin/bash
#################################################################################

pathtorepo="/work/clas12/users/gmat/rgcTargetPolarization"
USERNAME="$USER"

#################################################################################
hl="---------------------------------------------------------------"
if [ $# -lt 1 ]; then
  echo """
  USAGE: $0 [version] [flags(optional)]
  Automates the sending of slurm analysis jobs for RGC 
  Each job executes the ProcessInclusive.C macro in the previous directory
   - [version]: [8.3.2 or 8.3.4 or 8.4.0 or 8c.4.0] 
   - [flags]:
              -a      (append to existing data directory (./data/<version>/)
              -o      (overwrite existing data directory (./data/<version>/))
  """
  exit 2
fi

VERSIONS="8.3.2 8.3.4 8.4.0 8c.4.0"
nCPUs=4
memPerCPU=4000

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
NOWdir=/farm_out/gmat/clas12analysis.sidis.data/rgc/tpol/$NOW
if [ -d "${NOWdir}/" ]; then
    rm -r ${NOWdir}
fi
mkdir ${NOWdir}
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

##################################################################################################
PWD=$pwd
datadir=/volatile/clas12/users/gmat/clas12analysis.sidis.data/rgc/tpol/data/$version

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
trainhipodir="/volatile/clas12/rg-c/production/ana_data/*/$version/dst/train/sidisdvcs/*.hipo"
reconhipodir="/volatile/clas12/rg-c/production/ana_data/*/$version/dst/recon/*.hipo"
file_count=$(ls -1 $trainhipodir | wc -l)
##############################################################################################################
echo $hl
echo "Reading RCDB quantities (4 total)"
echo $hl
echo "Reading in target types"
targets=$(python readRCDB.py $trainhipodir "target")
echo "Reading in HWP status"
hwps=$(python readRCDB.py $trainhipodir "half_wave_plate")
echo "Reading in RCDB Tpol"
tpols=$(python readRCDB.py $trainhipodir "target_polarization")
echo "Reading in Beam Energies"
beamEs=$(python readRCDB.py $trainhipodir "beam_energy")
echo "Done reading RCDB"
echo $hl

echo $targets $hwps $tpols $beamEs



for ((i=0;i<$file_count;i++)); do

    hipo=`echo $trainhipodir | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
    targ=`echo $targets | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
    hwp=`echo $hwps | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
    tpol=`echo $tpols | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`
    beamE=`echo $beamEs | awk -v n=$((i+1)) '{print $n}' | tr -d "[',\[\]]"`

    cookType=""
    if [[ $hipo == *"/TBT/"* ]]; then
	cookType="TBT"
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
#SBATCH --partition=production
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
