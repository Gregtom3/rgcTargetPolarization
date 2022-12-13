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
   - [version]: [8.3.2 or 8.3.4]
   - [flags]:
              -a      (append to existing data directory (./data/<version>/)
              -o      (overwrite existing data directory (./data/<version>/))
  """
  exit 2
fi

VERSIONS="8.3.2 8.3.4"
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

version=${args[0]}

if ! echo "$VERSIONS" | grep -q "$version"; then
    echo $hl
    echo "ERROR: Version $version not valid. Must use from following list [$VERSIONS]"
    exit 2
fi

##################################################################################################
PWD=$pwd
datadir=$pathtorepo/$version

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
##############################################################################################################
for hipo in $trainhipodir; do
    echo $hipo
done
